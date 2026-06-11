import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:social_gallery/data/datasources/photo_manager_datasource.dart';
import 'package:social_gallery/data/local/app_database.dart';
import 'package:social_gallery/data/mappers/entity_mappers.dart';
import 'package:social_gallery/core/sync/gallery_sync_progress.dart';
import 'package:social_gallery/data/repositories/preferences_repository.dart';
import 'package:social_gallery/domain/models/feed_item.dart';
import 'package:social_gallery/domain/models/folder_with_stories.dart';
import 'package:social_gallery/domain/models/media_item.dart' as domain;

class MediaRepository {
  MediaRepository(this._db, this._photoManager, this._preferences);

  final AppDatabase _db;
  final PhotoManagerDatasource _photoManager;
  final PreferencesRepository _preferences;

  static const pageSize = 60;
  static const storyWindowHours = 24;

  Future<void> syncFromDevice({
    bool fastScan = false,
    bool Function()? shouldCancel,
    GallerySyncProgressCallback? onProgress,
  }) async {
    final existingFolders = await _db.select(_db.folders).get();
    final statusMap = {for (final f in existingFolders) f.path: f.followStatus};

    final favoriteIds = <int>{};
    final existingMedia = await _db.select(_db.mediaItems).get();
    for (final row in existingMedia) {
      if (row.isFavorite) favoriteIds.add(row.id);
    }

    onProgress?.call(
      const GallerySyncProgress(
        phase: 'folders',
        detail: 'Reading albums on your device',
      ),
    );

    final folderRows = await _photoManager.loadFolders(
      statusMap,
      _preferences.hasCompletedInitialSetup,
    );
    if (shouldCancel?.call() == true) return;
    await _db.upsertFolders(folderRows);

    final mediaRows = await _photoManager.loadAllMedia(
      fastScan: fastScan,
      shouldCancel: shouldCancel,
      onProgress: onProgress,
    );
    if (shouldCancel?.call() == true) return;

    onProgress?.call(
      GallerySyncProgress(
        phase: 'saving',
        detail: 'Saving ${mediaRows.length} items to your library',
        processed: 0,
        total: mediaRows.length,
      ),
    );

    final mergedMedia = mediaRows.map((row) {
      final id = row.id.value;
      if (favoriteIds.contains(id)) {
        return row.copyWith(isFavorite: const Value(true));
      }
      return row;
    }).toList();
    await _db.replaceAllMedia(mergedMedia);
    await _db.updateFolderCounts();

    onProgress?.call(
      const GallerySyncProgress(
        phase: 'finishing',
        detail: 'Finishing setup',
      ),
    );

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
      grouped.putIfAbsent(row.folderPath, () => []).add(mediaItemFromRow(row));
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
      final aDate = a.latestMedia.isEmpty ? 0 : a.latestMedia.first.dateAdded;
      final bDate = b.latestMedia.isEmpty ? 0 : b.latestMedia.first.dateAdded;
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

  Future<List<domain.MediaItem>> getGalleryMediaPage(int page) async {
    return getExplorePage(page);
  }

  Future<List<domain.MediaItem>> searchExplorePage(
    String query,
    int page,
  ) async {
    if (query.trim().isEmpty) {
      return getExplorePage(page);
    }
    final rows = await _db.searchExploreMedia(
      query.trim(),
      limit: pageSize,
      offset: page * pageSize,
    );
    return rows.map(mediaItemFromRow).toList();
  }

  Stream<List<domain.MediaItem>> watchFavorites() {
    return _db.watchFavoritesMedia().map(
      (rows) => rows.map(mediaItemFromRow).toList(),
    );
  }

  Stream<List<domain.MediaItem>> watchFolderMedia(String folderPath) {
    return _db
        .watchMediaInFolder(folderPath)
        .map((rows) => rows.map(mediaItemFromRow).toList());
  }

  Future<void> setFavorite(int id, bool favorite) {
    return _db.setFavorite(id, favorite);
  }

  Future<List<domain.MediaItem>> getPotentialDuplicates() async {
    final rows = await _db.getPotentialDuplicateMedia();
    return rows.map(mediaItemFromRow).toList();
  }

  Future<List<domain.MediaItem>> getOrganizeMediaPool() async {
    final rows = await _db.getOrganizeMediaPool();
    return rows.map(mediaItemFromRow).toList();
  }

  Future<List<domain.MediaItem>> getAllHomeFeedMedia() async {
    final rows = await _db.getAllHomeFeedMedia();
    return rows.map(mediaItemFromRow).toList();
  }

  Future<List<domain.MediaItem>> getFavoriteMediaList() async {
    final rows = await _db.getFavoriteMediaList();
    return rows.map(mediaItemFromRow).toList();
  }

  Future<domain.MediaItem?> getMediaById(int id) async {
    final row = await (_db.select(
      _db.mediaItems,
    )..where((m) => m.id.equals(id))).getSingleOrNull();
    return row == null ? null : mediaItemFromRow(row);
  }

  Future<List<domain.MediaItem>> getMediaByIds(Set<int> ids) async {
    if (ids.isEmpty) return [];
    final rows = await (_db.select(_db.mediaItems)
          ..where((m) => m.id.isIn(ids.toList())))
        .get();
    return rows.map(mediaItemFromRow).toList();
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

  Future<void> markStoryAsViewed(String folderPath) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.folders)..where((f) => f.path.equals(folderPath)))
        .write(FoldersCompanion(storyLastViewedTime: Value(now)));
  }

  // --- NEW WORK: Move, Trash, Restore, and Cleanup repository methods ---

  Future<bool> createFolderAndMoveMedia(
    String folderName,
    List<domain.MediaItem> items,
  ) async {
    final newPath = await _photoManager.createAlbumFolder(folderName);
    if (newPath == null) return false;
    await moveMedia(items, newPath);
    await syncFromDevice();
    return true;
  }

  Future<int> moveMedia(
    List<domain.MediaItem> items,
    String targetFolderPath,
  ) async {
    if (items.isEmpty) return 0;

    final resolvedPath =
        await _photoManager.resolveTargetAlbumId(targetFolderPath) ??
            targetFolderPath;

    final folder = await (_db.select(_db.folders)
          ..where((f) => f.path.equals(resolvedPath)))
        .getSingleOrNull();
    final folderName = folder?.name ?? _folderNameFromPath(resolvedPath);

    final moved = await _photoManager.moveAssetsOnDisk(
      items.map((item) => item.uri).toList(),
      targetFolderPath,
    );

    if (moved > 0) {
      final movedItems = items.take(moved).toList();
      await _db.moveMediaItems(
        movedItems.map((item) => item.id).toList(),
        resolvedPath,
        folderName,
      );
      await _db.updateFolderCounts();
    } else {
      debugPrint(
        'moveMedia: 0/${items.length} moved to $targetFolderPath '
        '(resolved: $resolvedPath)',
      );
    }

    return moved;
  }

  String _folderNameFromPath(String path) {
    if (path.contains('/')) {
      return path.substring(path.lastIndexOf('/') + 1);
    }
    return path;
  }

  Future<void> trashMedia(List<domain.MediaItem> items) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final origPaths = <int, String>{};
    final successIds = <int>[];

    for (final item in items) {
      final originalPath = await _photoManager.trashAssetOnDisk(item.uri);
      if (originalPath != null) {
        origPaths[item.id] = originalPath;
        successIds.add(item.id);
      }
    }

    if (successIds.isNotEmpty) {
      await _db.trashMediaItems(successIds, now, origPaths);
    }
  }

  Future<void> restoreMedia(List<domain.MediaItem> items) async {
    final successIds = <int>[];
    for (final item in items) {
      if (item.originalPath != null) {
        final restored = await _photoManager.restoreAssetOnDisk(
          item.originalPath!,
        );
        if (restored) {
          successIds.add(item.id);
        }
      }
    }
    if (successIds.isNotEmpty) {
      await _db.restoreMediaItems(successIds);
    }
  }

  Future<void> permanentlyDeleteMedia(List<domain.MediaItem> items) async {
    final ids = <int>[];
    for (final item in items) {
      if (item.originalPath != null) {
        await _photoManager.deleteTrashedFile(item.originalPath!);
      }
      ids.add(item.id);
    }
    await _db.deleteMediaByIds(ids);
    await _db.updateFolderCounts();
  }

  Future<void> cleanupExpiredTrash(int retentionDays) async {
    final retentionMs = retentionDays * 24 * 60 * 60 * 1000;
    final beforeTimestamp = DateTime.now().millisecondsSinceEpoch - retentionMs;
    final expiredRows = await _db.getExpiredTrashedMedia(beforeTimestamp);

    if (expiredRows.isNotEmpty) {
      final expiredItems = expiredRows.map(mediaItemFromRow).toList();
      await permanentlyDeleteMedia(expiredItems);
    }
  }

  Stream<List<domain.MediaItem>> watchTrashedMedia() {
    return _db.watchTrashedMedia().map(
      (rows) => rows.map(mediaItemFromRow).toList(),
    );
  }
}
