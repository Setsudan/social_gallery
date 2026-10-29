import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:social_gallery/core/exif/exif_reader.dart';
import 'package:social_gallery/core/media/asset_entity_cache.dart';
import 'package:social_gallery/core/media/filesystem_image_loader.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';
import 'package:social_gallery/data/datasources/photo_manager_datasource.dart';
import 'package:social_gallery/data/local/app_database.dart';
import 'package:social_gallery/data/mappers/entity_mappers.dart';
import 'package:social_gallery/core/sync/gallery_sync_progress.dart';
import 'package:social_gallery/core/sync/media_sync_service.dart';
import 'package:social_gallery/data/repositories/media_sync_repository.dart';
import 'package:social_gallery/data/repositories/preferences_repository.dart';
import 'package:social_gallery/domain/models/backup_state.dart';
import 'package:social_gallery/domain/models/feed_item.dart';
import 'package:social_gallery/domain/models/folder_with_stories.dart';
import 'package:social_gallery/domain/models/explore_search_query.dart';
import 'package:social_gallery/domain/models/media_content_kind.dart';
import 'package:social_gallery/domain/models/media_item.dart' as domain;

/// Single entry point for indexed media: sync, queries, favorites, trash, and device I/O.
class MediaRepository {
  MediaRepository(
    this._database,
    this._photoManagerDatasource,
    PreferencesRepository preferencesRepository, {
    MediaSyncService? syncService,
  }) : _syncService =
           syncService ??
           MediaSyncService(
             MediaSyncRepository(_database),
             _photoManagerDatasource,
             preferencesRepository,
           );

  final AppDatabase _database;
  final PhotoManagerDatasource _photoManagerDatasource;
  final MediaSyncService _syncService;

  /// Page size for home feed, gallery, and explore pagination.
  static const pageSize = 60;
  static const storyWindowHours = 24;

  /// Reads folders and media from the device, merges favorites/trash, writes to Drift.
  Future<void> syncFromDevice({
    bool fastScan = false,
    bool Function()? shouldCancel,
    GallerySyncProgressCallback? onProgress,
  }) => _syncService.syncFromDevice(
    fastScan: fastScan,
    shouldCancel: shouldCancel,
    onProgress: onProgress,
  );

  Future<List<FolderWithStories>> getFoldersWithStories() async {
    final windowMs = storyWindowHours * 60 * 60 * 1000;
    final since = DateTime.now().millisecondsSinceEpoch - windowMs;

    final storyFolders = await _database.getStoriesEnabledFolders();
    final folderMap = {for (final f in storyFolders) f.path: f};
    final recentMedia = await _database.getMediaAddedAfter(since);

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
    final rows = await _database.getHomeFeedMediaPage(
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
    final rows = await _database.getExploreMediaPage(
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
    final rows = await _database.searchExploreMediaFiltered(
      text: query.text,
      labels: query.labels,
      color: query.color,
      placeQuery: query.placeQuery,
      dateFromMs: query.dateFromMs,
      dateToMs: query.dateToMs,
      cameraMake: query.cameraMake,
      cameraModel: query.cameraModel,
      contentFilter: query.contentFilter.name,
      minFaceCount: query.minFaceCount,
      limit: pageSize,
      offset: page * pageSize,
    );
    return rows.map(mediaItemFromRow).toList();
  }

  Future<List<domain.MediaItem>> getContentKindPage(
    MediaContentKind kind,
    int page, {
    String? ocrQuery,
  }) async {
    final rows = await _database.getMediaByContentKindPage(
      contentKind: kind.value,
      limit: pageSize,
      offset: page * pageSize,
      ocrQuery: ocrQuery,
    );
    return rows.map(mediaItemFromRow).toList();
  }

  Future<domain.MediaItem?> pickFolderWidgetMedia(
    String folderPath, {
    bool random = true,
  }) async {
    final row = await _database.pickFolderMedia(
      folderPath: folderPath,
      random: random,
    );
    return row == null ? null : mediaItemFromRow(row);
  }

  Future<domain.MediaItem?> pickFavoriteWidgetMedia({
    bool random = true,
  }) async {
    final row = await _database.pickFavoriteMedia(random: random);
    return row == null ? null : mediaItemFromRow(row);
  }

  Future<domain.MediaItem?> pickOnThisDayWidgetMedia({
    bool random = true,
  }) async {
    final row = await _database.pickOnThisDayMedia(random: random);
    return row == null ? null : mediaItemFromRow(row);
  }

  Future<void> updateContentKind(int mediaId, MediaContentKind kind) {
    return _database.updateMediaContentKind(mediaId, kind.value);
  }

  Future<int> backfillScreenshotContentKinds() {
    return _database.backfillScreenshotContentKinds();
  }

  Future<List<domain.MediaItem>> getAllSearchableMedia() async {
    final rows = await _database.getAllSearchableMedia();
    return rows.map(mediaItemFromRow).toList();
  }

  Stream<List<domain.MediaItem>> watchFavorites() {
    return _database.watchFavoritesMedia().map(
      (rows) => rows.map(mediaItemFromRow).toList(),
    );
  }

  Future<List<domain.MediaItem>> getFavoritesPage(int page) async {
    final rows = await _database.getFavoritesMediaPage(
      limit: pageSize,
      offset: page * pageSize,
    );
    return rows.map(mediaItemFromRow).toList();
  }

  Future<List<domain.MediaItem>> getFolderMediaPage(
    String folderPath,
    int page,
  ) async {
    final rows = await _database.getMediaInFolderPage(
      folderPath,
      limit: pageSize,
      offset: page * pageSize,
    );
    return rows.map(mediaItemFromRow).toList();
  }

  Future<void> setFavorite(int id, bool favorite) {
    return _database.setFavorite(id, favorite);
  }

  Future<List<domain.MediaItem>> getPotentialDuplicates() async {
    await backfillFilesystemImageDimensions();
    final rows = await _database.getPotentialDuplicateMedia();
    return rows.map(mediaItemFromRow).toList();
  }

  Future<void> backfillFilesystemImageDimensions() async {
    if (!usesFilesystemGallery) return;

    final rows = await _database.getHomeFeedImagesMissingDimensions();
    for (final row in rows) {
      final dimensions = await readFilesystemImageDimensions(row.uri);
      if (dimensions == null) continue;
      await _database.updateMediaDimensions(
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
    final rows = await _database.getHomeFeedImagesMissingLocation();
    if (rows.isEmpty) return 0;

    var updated = 0;
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final coords = await _readGpsForMediaRow(row);
      if (coords != null) {
        await _database.updateMediaLocation(row.id, coords.$1, coords.$2);
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
    final rows = await _database.getOrganizeMediaPool();
    return rows.map(mediaItemFromRow).toList();
  }

  Future<List<domain.MediaItem>> getAllHomeFeedMedia() async {
    final rows = await _database.getAllHomeFeedMedia();
    return rows.map(mediaItemFromRow).toList();
  }

  Future<List<domain.MediaItem>> getMediaWithLocation() async {
    final rows = await _database.getMediaWithLocation();
    return rows.map(mediaItemFromRow).toList();
  }

  Future<List<domain.MediaItem>> getFavoriteMediaList() async {
    final rows = await _database.getFavoriteMediaList();
    return rows.map(mediaItemFromRow).toList();
  }

  Future<domain.MediaItem?> getMediaById(int id) async {
    final row = await (_database.select(
      _database.mediaItems,
    )..where((m) => m.id.equals(id))).getSingleOrNull();
    return row == null ? null : mediaItemFromRow(row);
  }

  Future<List<domain.MediaItem>> getMediaByIds(Set<int> ids) async {
    if (ids.isEmpty) return [];
    final rows = await (_database.select(
      _database.mediaItems,
    )..where((m) => m.id.isIn(ids.toList()))).get();
    return rows.map(mediaItemFromRow).toList();
  }

  Future<bool> deleteFromDevice(List<domain.MediaItem> items) async {
    final assetIds = items.map((e) => e.uri).toList();
    final deleted = await _photoManagerDatasource.deleteAssets(assetIds);
    if (deleted) {
      await _database.deleteMediaByIds(items.map((e) => e.id).toList());
      await _database.updateFolderCounts();
      await _database.repairFolderCovers();
    }
    return deleted;
  }

  Future<void> markStoryAsViewed(String folderPath) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_database.update(_database.folders)
          ..where((f) => f.path.equals(folderPath)))
        .write(FoldersCompanion(storyLastViewedTime: Value(now)));
  }

  // --- NEW WORK: Move, Trash, Restore, and Cleanup repository methods ---

  Future<bool> createFolderAndMoveMedia(
    String folderName,
    List<domain.MediaItem> items,
  ) async {
    final newPath = await _photoManagerDatasource.createAlbumFolder(folderName);
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

    final sourcePaths = {
      for (final item in items)
        if (item.folderPath.isNotEmpty) item.folderPath,
    };

    final resolvedPath =
        await _photoManagerDatasource.resolveTargetAlbumId(targetFolderPath) ??
        targetFolderPath;

    final folder = await (_database.select(
      _database.folders,
    )..where((f) => f.path.equals(resolvedPath))).getSingleOrNull();
    final folderName = folder?.name ?? _folderNameFromPath(resolvedPath);

    final movedByUri = await _photoManagerDatasource.moveAssetsOnDisk(
      items.map((item) => item.uri).toList(),
      targetFolderPath,
    );

    if (movedByUri.isEmpty) {
      debugPrint(
        'moveMedia: 0/${items.length} moved to $targetFolderPath '
        '(resolved: $resolvedPath)',
      );
      return 0;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final byUri = {for (final item in items) item.uri: item};
    var uriChanged = false;

    for (final entry in movedByUri.entries) {
      final item = byUri[entry.key];
      if (item == null) continue;
      final newUri = entry.value;
      if (newUri != item.uri) {
        uriChanged = true;
        final newId = newUri.hashCode & 0x7FFFFFFF;
        await _database.moveMediaItemWithUri(
          id: item.id,
          targetFolderPath: resolvedPath,
          targetFolderName: folderName,
          newUri: newUri,
          newId: newId,
          dateModifiedMs: now,
        );
      }
    }

    if (!uriChanged) {
      final movedIds = [
        for (final uri in movedByUri.keys)
          if (byUri[uri] != null) byUri[uri]!.id,
      ];
      await _database.moveMediaItems(
        movedIds,
        resolvedPath,
        folderName,
        dateModifiedMs: now,
      );
    }

    await _database.repairFolderCoversForPaths({...sourcePaths, resolvedPath});
    for (final oldUri in movedByUri.keys) {
      AssetEntityCache.evict(oldUri);
    }
    return movedByUri.length;
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
      final originalPath = await _photoManagerDatasource.trashAssetOnDisk(
        item.uri,
      );
      if (originalPath != null) {
        origPaths[item.id] = originalPath;
        successIds.add(item.id);
      }
    }

    if (successIds.isNotEmpty) {
      await _database.trashMediaItems(successIds, now, origPaths);
      await _database.repairFolderCovers();
    }
  }

  Future<void> restoreMedia(List<domain.MediaItem> items) async {
    final successIds = <int>[];
    for (final item in items) {
      if (item.originalPath != null) {
        final restored = await _photoManagerDatasource.restoreAssetOnDisk(
          item.originalPath!,
        );
        if (restored) {
          successIds.add(item.id);
        }
      }
    }
    if (successIds.isNotEmpty) {
      await _database.restoreMediaItems(successIds);
      await _database.repairFolderCovers();
    }
  }

  Future<void> permanentlyDeleteMedia(List<domain.MediaItem> items) async {
    final ids = <int>[];
    for (final item in items) {
      if (item.originalPath != null) {
        await _photoManagerDatasource.deleteTrashedFile(item.originalPath!);
      }
      ids.add(item.id);
    }
    await _database.deleteMediaByIds(ids);
    await _database.updateFolderCounts();
    await _database.repairFolderCovers();
  }

  Future<void> repairFolderCovers() {
    return _database.repairFolderCovers();
  }

  Future<void> cleanupExpiredTrash(int retentionDays) async {
    final retentionMs = retentionDays * 24 * 60 * 60 * 1000;
    final beforeTimestamp = DateTime.now().millisecondsSinceEpoch - retentionMs;
    final expiredRows = await _database.getExpiredTrashedMedia(beforeTimestamp);

    if (expiredRows.isNotEmpty) {
      final expiredItems = expiredRows.map(mediaItemFromRow).toList();
      await permanentlyDeleteMedia(expiredItems);
    }
  }

  Stream<List<domain.MediaItem>> watchTrashedMedia() {
    return _database.watchTrashedMedia().map(
      (rows) => rows.map(mediaItemFromRow).toList(),
    );
  }

  Future<List<domain.MediaItem>> getMediaPendingBackup({
    int limit = 100,
    String? folderPath,
  }) async {
    final rows = await _database.getMediaPendingBackupWithFolder(
      limit: limit,
      folderPath: folderPath,
    );
    return rows
        .map(
          (entry) =>
              mediaItemFromRow(entry.row).copyWith(isVault: entry.isVault),
        )
        .toList();
  }

  Future<List<PendingBackupFolder>> getPendingBackupFolders() {
    return _database.getPendingBackupFolders();
  }

  Future<bool> hasPendingVaultBackup() => _database.hasPendingVaultBackup();

  Future<int> countMediaPendingBackup({String? folderPath}) {
    return _database.countMediaPendingBackup(folderPath: folderPath);
  }

  Future<void> updateBackupState(int id, MediaBackupState state) {
    return _database.updateMediaBackupState(id, state.value);
  }

  Future<void> markMediaBackedUp(int id) {
    return _database.markMediaBackedUp(
      id,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> resetStaleBackupInProgress() {
    return _database.resetStaleBackupInProgress();
  }

  Future<List<domain.MediaItem>> getBackedUpMediaSample({
    required int offset,
    required int limit,
  }) async {
    final rows = await _database.getBackedUpMediaSampleWithFolder(
      offset: offset,
      limit: limit,
    );
    return rows
        .map(
          (entry) =>
              mediaItemFromRow(entry.row).copyWith(isVault: entry.isVault),
        )
        .toList();
  }

  Future<int> countBackedUpMedia() {
    return _database.countBackedUpMedia();
  }

  Future<void> reconcileBackupStates({
    required Iterable<int> presentIds,
    required Iterable<int> mismatchIds,
    required Iterable<int> missingIds,
  }) async {
    final syncedAt = DateTime.now().millisecondsSinceEpoch;
    await _database.markMediaIdsBackedUp(presentIds, syncedAt);
    final resetIds = [...mismatchIds, ...missingIds];
    await _database.markMediaIdsPending(resetIds);
  }

  Future<void> markVerifiedMissingAsPending(Iterable<int> ids) {
    return _database.markMediaIdsPending(ids);
  }

  Future<List<PendingBackupFolder>> getPendingCloudBackupFolders() {
    return _database.getPendingCloudBackupFolders();
  }

  Future<List<domain.MediaItem>> getMediaPendingCloudBackup({
    int limit = 100,
    String? folderPath,
  }) async {
    final rows = await _database.getMediaPendingCloudBackup(
      limit: limit,
      folderPath: folderPath,
    );
    return rows.map(mediaItemFromRow).toList();
  }

  Future<int> countMediaPendingCloudBackup({String? folderPath}) {
    return _database.countMediaPendingCloudBackup(folderPath: folderPath);
  }

  Future<void> updateCloudBackupState(int id, MediaBackupState state) {
    return _database.updateMediaCloudBackupState(id, state.value);
  }

  Future<void> markMediaCloudBackedUp({
    required int id,
    required String objectKey,
  }) {
    return _database.markMediaCloudBackedUp(
      id: id,
      syncedAtMs: DateTime.now().millisecondsSinceEpoch,
      objectKey: objectKey,
    );
  }

  Future<void> resetStaleCloudBackupInProgress() {
    return _database.resetStaleCloudBackupInProgress();
  }

  Future<List<domain.MediaItem>> getCloudBackedUpMedia({
    int limit = 100,
    int offset = 0,
  }) async {
    final rows = await _database.getCloudBackedUpMedia(
      limit: limit,
      offset: offset,
    );
    return rows.map(mediaItemFromRow).toList();
  }

  Future<int> countCloudBackedUpMedia() => _database.countCloudBackedUpMedia();

  Future<void> upsertCloudBackupObject({
    required int mediaId,
    required String objectKey,
    required String plaintextChecksum,
    required int size,
  }) {
    return _database.upsertCloudBackupObject(
      mediaId: mediaId,
      objectKey: objectKey,
      plaintextChecksum: plaintextChecksum,
      size: size,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<CloudBackupObject?> getCloudBackupObject(int mediaId) {
    return _database.getCloudBackupObject(mediaId);
  }

  Future<List<CloudBackupObject>> listCloudBackupObjects({
    int limit = 200,
    int offset = 0,
  }) {
    return _database.listCloudBackupObjects(limit: limit, offset: offset);
  }

  Future<void> clearCloudBackupInventory() =>
      _database.clearCloudBackupInventory();
}
