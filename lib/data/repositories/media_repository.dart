import 'package:drift/drift.dart';
import 'package:social_gallery/data/datasources/photo_manager_datasource.dart';
import 'package:social_gallery/data/local/app_database.dart';
import 'package:social_gallery/data/mappers/entity_mappers.dart';
import 'package:social_gallery/data/repositories/preferences_repository.dart';
import 'package:social_gallery/domain/models/feed_item.dart';
import 'package:social_gallery/domain/models/folder_with_stories.dart';
import 'package:social_gallery/domain/models/media_item.dart' as domain;

class MediaRepository {
  MediaRepository(
    this._db,
    this._photoManager,
    this._preferences,
  );

  final AppDatabase _db;
  final PhotoManagerDatasource _photoManager;
  final PreferencesRepository _preferences;

  static const pageSize = 60;
  static const storyWindowHours = 24;

  Future<void> syncFromDevice() async {
    final existingFolders = await _db.select(_db.folders).get();
    final statusMap = {
      for (final f in existingFolders) f.path: f.followStatus,
    };

    final favoriteIds = <int>{};
    final existingMedia = await _db.select(_db.mediaItems).get();
    for (final row in existingMedia) {
      if (row.isFavorite) favoriteIds.add(row.id);
    }

    final folderRows = await _photoManager.loadFolders(
      statusMap,
      _preferences.hasCompletedInitialSetup,
    );
    await _db.upsertFolders(folderRows);

    final mediaRows = await _photoManager.loadAllMedia();
    final mergedMedia = mediaRows.map((row) {
      final id = row.id.value;
      if (favoriteIds.contains(id)) {
        return row.copyWith(isFavorite: const Value(true));
      }
      return row;
    }).toList();
    await _db.replaceAllMedia(mergedMedia);
    await _db.updateFolderCounts();

    if (!_preferences.hasCompletedInitialSetup) {
      await _preferences.setInitialSetupComplete();
    }
  }

  Future<List<FolderWithStories>> getFoldersWithStories() async {
    final windowMs = storyWindowHours * 60 * 60 * 1000;
    final since = DateTime.now().millisecondsSinceEpoch - windowMs;

    final storyFolders = await _db.getStoriesEnabledFolders();
    final folderMap = {for (final f in storyFolders) f.path: f};
    final recentMedia = await _db.getMediaAddedAfter(since);

    final grouped = <String, List<domain.MediaItem>>{};
    for (final row in recentMedia) {
      if (!folderMap.containsKey(row.folderPath)) continue;
      grouped
          .putIfAbsent(row.folderPath, () => [])
          .add(mediaItemFromRow(row));
    }

    final results = <FolderWithStories>[];
    for (final entry in grouped.entries) {
      final folder = folderMap[entry.key];
      if (folder == null || entry.value.isEmpty) continue;

      final sorted = [...entry.value]
        ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
      final lastViewed = folder.storyLastViewedTime;
      final hasUnseen = sorted.any((m) => m.dateAdded > lastViewed);

      results.add(
        FolderWithStories(
          folderName: sorted.first.folderName,
          folderPath: entry.key,
          newMediaCount: sorted.length,
          latestMedia: sorted,
          hasUnseenContent: hasUnseen,
          storyLastViewedTime: lastViewed,
        ),
      );
    }

    results.sort((a, b) {
      final unseen = b.hasUnseenContent.toString().compareTo(
            a.hasUnseenContent.toString(),
          );
      if (unseen != 0) return unseen;
      final aDate =
          a.latestMedia.isEmpty ? 0 : a.latestMedia.first.dateAdded;
      final bDate =
          b.latestMedia.isEmpty ? 0 : b.latestMedia.first.dateAdded;
      return bDate.compareTo(aDate);
    });

    return results;
  }

  Future<List<FeedItem>> getHomeFeedPage(int page) async {
    final rows = await _db.getHomeFeedMediaPage(
      limit: pageSize,
      offset: page * pageSize,
    );
    return rows
        .map(
          (row) => FeedItem(
            folderName: row.folderName,
            folderPath: row.folderPath,
            media: mediaItemFromRow(row),
          ),
        )
        .toList();
  }

  Future<List<domain.MediaItem>> getExplorePage(int page) async {
    final rows = await _db.getExploreMediaPage(
      limit: pageSize,
      offset: page * pageSize,
    );
    return rows.map(mediaItemFromRow).toList();
  }

  Future<List<domain.MediaItem>> searchExplore(String query) async {
    if (query.trim().isEmpty) {
      return getExplorePage(0);
    }
    final rows = await _db.searchExploreMedia(query.trim());
    return rows.map(mediaItemFromRow).toList();
  }

  Stream<List<domain.MediaItem>> watchFavorites() {
    return _db.watchFavoritesMedia().map(
          (rows) => rows.map(mediaItemFromRow).toList(),
        );
  }

  Stream<List<domain.MediaItem>> watchFolderMedia(String folderPath) {
    return _db.watchMediaInFolder(folderPath).map(
          (rows) => rows.map(mediaItemFromRow).toList(),
        );
  }

  Future<void> setFavorite(int id, bool favorite) {
    return _db.setFavorite(id, favorite);
  }

  Future<List<domain.MediaItem>> getPotentialDuplicates() async {
    final rows = await _db.getPotentialDuplicateMedia();
    return rows.map(mediaItemFromRow).toList();
  }

  Future<domain.MediaItem?> getMediaById(int id) async {
    final row = await (_db.select(_db.mediaItems)
          ..where((m) => m.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : mediaItemFromRow(row);
  }

  Future<bool> deleteFromDevice(List<domain.MediaItem> items) async {
    final assetIds = items.map((e) => e.uri).toList();
    final deleted = await _photoManager.deleteAssets(assetIds);
    if (deleted) {
      await _db.deleteMediaByIds(items.map((e) => e.id).toList());
      await _db.updateFolderCounts();
    }
    return deleted;
  }
}
