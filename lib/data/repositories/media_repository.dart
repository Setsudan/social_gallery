import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:social_gallery/core/exif/exif_reader.dart';
import 'package:social_gallery/core/media/filesystem_image_loader.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';
import 'package:social_gallery/data/datasources/photo_manager_datasource.dart';
import 'package:social_gallery/data/local/app_database.dart';
import 'package:social_gallery/data/mappers/entity_mappers.dart';
import 'package:social_gallery/core/sync/gallery_sync_progress.dart';
import 'package:social_gallery/data/repositories/preferences_repository.dart';
import 'package:social_gallery/domain/models/backup_state.dart';
import 'package:social_gallery/domain/models/feed_item.dart';
import 'package:social_gallery/domain/models/folder_with_stories.dart';
import 'package:social_gallery/domain/models/explore_search_query.dart';
import 'package:social_gallery/domain/models/media_item.dart' as domain;

/// Single entry point for indexed media: sync, queries, favorites, trash, and device I/O.
class MediaRepository {
  MediaRepository(this._db, this._photoManager, this._preferences);

  final AppDatabase _db;
  final PhotoManagerDatasource _photoManager;
  final PreferencesRepository _preferences;

  /// Page size for home feed, gallery, and explore pagination.
  static const pageSize = 60;
  static const storyWindowHours = 24;

  /// Reads folders and media from the device, merges favorites/trash, writes to Drift.
  Future<void> syncFromDevice({
    bool fastScan = false,
    bool Function()? shouldCancel,
    GallerySyncProgressCallback? onProgress,
  }) async {
    final existingFolders = await _db.select(_db.folders).get();
    final statusMap = {for (final f in existingFolders) f.path: f.followStatus};

    final favoriteIds = <int>{};
    final trashedIds = <int>{};
    final existingById = <int, MediaRow>{};
    final existingMedia = await _db.select(_db.mediaItems).get();
    for (final row in existingMedia) {
      existingById[row.id] = row;
      if (row.isFavorite) favoriteIds.add(row.id);
      if (row.isTrashed) trashedIds.add(row.id);
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
      final existing = existingById[id];
      var merged = row;
      if (favoriteIds.contains(id)) {
        merged = merged.copyWith(isFavorite: const Value(true));
      }
      if (existing != null) {
        if (existing.isTrashed) {
          merged = merged.copyWith(
            isTrashed: const Value(true),
            trashedAt: Value(existing.trashedAt),
            originalPath: Value(existing.originalPath),
          );
        }
        merged = merged.copyWith(
          backupState: Value(existing.backupState),
          lastSyncTime: Value(existing.lastSyncTime),
        );
        final incomingLat =
            row.latitude.present ? row.latitude.value : null;
        final incomingLng =
            row.longitude.present ? row.longitude.value : null;
        final hasIncomingLocation = incomingLat != null &&
            incomingLng != null &&
            incomingLat != 0 &&
            incomingLng != 0;
        final hasExistingLocation = existing.latitude != null &&
            existing.longitude != null &&
            existing.latitude != 0 &&
            existing.longitude != 0;
        if (!hasIncomingLocation && hasExistingLocation) {
          merged = merged.copyWith(
            latitude: Value(existing.latitude),
            longitude: Value(existing.longitude),
          );
        }
      }
      return merged;
    }).toList();
    await _db.syncMediaItems(mergedMedia, preserveIds: trashedIds);
    await _db.updateFolderCounts();
    await _db.repairFolderCovers();

    onProgress?.call(
      const GallerySyncProgress(
        phase: 'finishing',
        detail: 'Finishing setup',
      ),
    );
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
    ExploreSearchQuery query,
    int page,
  ) async {
    if (query.isEmpty) {
      return getExplorePage(page);
    }
    final rows = await _db.searchExploreMediaFiltered(
      text: query.text,
      label: query.label,
      color: query.color,
      limit: pageSize,
      offset: page * pageSize,
    );
    return rows.map(mediaItemFromRow).toList();
  }

  Future<List<domain.MediaItem>> getAllSearchableMedia() async {
    final rows = await _db.getAllSearchableMedia();
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
    await backfillFilesystemImageDimensions();
    final rows = await _db.getPotentialDuplicateMedia();
    return rows.map(mediaItemFromRow).toList();
  }

  Future<void> backfillFilesystemImageDimensions() async {
    if (!usesFilesystemGallery) return;

    final rows = await _db.getHomeFeedImagesMissingDimensions();
    for (final row in rows) {
      final dimensions = await readFilesystemImageDimensions(row.uri);
      if (dimensions == null) continue;
      await _db.updateMediaDimensions(
        row.id,
        dimensions.width,
        dimensions.height,
      );
    }
  }

  /// Reads GPS from EXIF or the device media index for items missing coordinates.
  Future<int> backfillMediaLocations({
    void Function(int processed, int total)? onProgress,
  }) async {
    final rows = await _db.getHomeFeedImagesMissingLocation();
    if (rows.isEmpty) return 0;

    var updated = 0;
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final coords = await _readGpsForMediaRow(row);
      if (coords != null) {
        await _db.updateMediaLocation(row.id, coords.$1, coords.$2);
        updated++;
      }
      if (i % 10 == 0 || i == rows.length - 1) {
        onProgress?.call(i + 1, rows.length);
      }
    }
    return updated;
  }

  Future<(double, double)?> _readGpsForMediaRow(MediaRow row) async {
    if (usesFilesystemGallery) {
      final exif = await readExifFromPath(row.uri);
      final lat = exif?.latitude;
      final lng = exif?.longitude;
      if (lat != null && lng != null && lat != 0 && lng != 0) {
        return (lat, lng);
      }
      return null;
    }

    final entity = await AssetEntity.fromId(row.uri);
    if (entity == null) return null;

    var lat = entity.latitude;
    var lng = entity.longitude;
    if (lat != null && lng != null && lat != 0 && lng != 0) {
      return (lat, lng);
    }

    final file = await entity.originFile ?? await entity.file;
    final exif = await readExifFromPath(file?.path);
    lat = exif?.latitude;
    lng = exif?.longitude;
    if (lat != null && lng != null && lat != 0 && lng != 0) {
      return (lat, lng);
    }
    return null;
  }

  Future<List<domain.MediaItem>> getOrganizeMediaPool() async {
    final rows = await _db.getOrganizeMediaPool();
    return rows.map(mediaItemFromRow).toList();
  }

  Future<List<domain.MediaItem>> getAllHomeFeedMedia() async {
    final rows = await _db.getAllHomeFeedMedia();
    return rows.map(mediaItemFromRow).toList();
  }

  Future<List<domain.MediaItem>> getMediaWithLocation() async {
    final rows = await _db.getMediaWithLocation();
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
      await _db.repairFolderCovers();
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

    final movedUris = await _photoManager.moveAssetsOnDisk(
      items.map((item) => item.uri).toList(),
      targetFolderPath,
    );

    if (movedUris.isNotEmpty) {
      final movedUriSet = movedUris.toSet();
      final movedItems =
          items.where((item) => movedUriSet.contains(item.uri)).toList();
      await _db.moveMediaItems(
        movedItems.map((item) => item.id).toList(),
        resolvedPath,
        folderName,
      );
      await _db.updateFolderCounts();
      await _db.repairFolderCovers();
    } else {
      debugPrint(
        'moveMedia: 0/${items.length} moved to $targetFolderPath '
        '(resolved: $resolvedPath)',
      );
    }

    return movedUris.length;
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
      await _db.repairFolderCovers();
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
      await _db.repairFolderCovers();
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
    await _db.repairFolderCovers();
  }

  Future<void> repairFolderCovers() {
    return _db.repairFolderCovers();
  }

  Future<void> refreshFolderAutoCovers() {
    return _db.repairFolderCovers();
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

  Future<List<domain.MediaItem>> getMediaPendingBackup({int limit = 100}) async {
    final rows = await _db.getMediaPendingBackupWithFolder(limit: limit);
    return rows
        .map(
          (entry) => mediaItemFromRow(entry.row).copyWith(isVault: entry.isVault),
        )
        .toList();
  }

  Future<bool> hasPendingVaultBackup() => _db.hasPendingVaultBackup();

  Future<int> countMediaPendingBackup() {
    return _db.countMediaPendingBackup();
  }

  Future<void> updateBackupState(int id, MediaBackupState state) {
    return _db.updateMediaBackupState(id, state.value);
  }

  Future<void> markMediaBackedUp(int id) {
    return _db.markMediaBackedUp(id, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> resetStaleBackupInProgress() {
    return _db.resetStaleBackupInProgress();
  }

  Future<List<domain.MediaItem>> getBackedUpMediaSample({
    required int offset,
    required int limit,
  }) async {
    final rows = await _db.getBackedUpMediaSampleWithFolder(
      offset: offset,
      limit: limit,
    );
    return rows
        .map(
          (entry) => mediaItemFromRow(entry.row).copyWith(isVault: entry.isVault),
        )
        .toList();
  }

  Future<int> countBackedUpMedia() {
    return _db.countBackedUpMedia();
  }

  Future<void> reconcileBackupStates({
    required Iterable<int> presentIds,
    required Iterable<int> mismatchIds,
    required Iterable<int> missingIds,
  }) async {
    final syncedAt = DateTime.now().millisecondsSinceEpoch;
    await _db.markMediaIdsBackedUp(presentIds, syncedAt);
    final resetIds = [...mismatchIds, ...missingIds];
    await _db.markMediaIdsPending(resetIds);
  }

  Future<void> markVerifiedMissingAsPending(Iterable<int> ids) {
    return _db.markMediaIdsPending(ids);
  }
}
