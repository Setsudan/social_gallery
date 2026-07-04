import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';

import 'tables/folders_table.dart';
import 'tables/location_place_cache_table.dart';
import 'tables/media_analysis_cache_table.dart';
import 'tables/media_items_table.dart';
import 'tables/travel_modes_table.dart';

part 'app_database.g.dart';

/// Local SQLite store for folders, media index, travel modes, and analysis cache.
@DriftDatabase(
  tables: [
    Folders,
    MediaItems,
    TravelModes,
    MediaAnalysisCache,
    LocationPlaceCache,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(mediaItems, mediaItems.isTrashed);
        await m.addColumn(mediaItems, mediaItems.trashedAt);
        await m.addColumn(mediaItems, mediaItems.originalPath);
      }
      if (from < 3) {
        await m.createTable(travelModes);
      }
      if (from < 4) {
        await m.addColumn(mediaItems, mediaItems.cameraMake);
        await m.addColumn(mediaItems, mediaItems.cameraModel);
        await m.addColumn(mediaItems, mediaItems.iso);
        await m.addColumn(mediaItems, mediaItems.shutterSpeed);
        await m.addColumn(mediaItems, mediaItems.focalLength);
        await m.addColumn(mediaItems, mediaItems.aperture);
        await m.createTable(mediaAnalysisCache);
      }
      if (from < 5) {
        await m.createTable(locationPlaceCache);
      }
      if (from < 6) {
        await m.addColumn(mediaAnalysisCache, mediaAnalysisCache.dominantColor);
      }
    },
  );

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'social_gallery.db'));
      return NativeDatabase(file);
    });
  }

  Stream<List<Folder>> watchFoldersByFollowStatus(String status) {
    return (select(folders)
          ..where((f) => f.followStatus.equals(status))
          ..orderBy([(f) => OrderingTerm.asc(f.name)]))
        .watch();
  }

  Stream<List<Folder>> watchAllFoldersOrdered() {
    return (select(
      folders,
    )..orderBy([(f) => OrderingTerm.asc(f.name)])).watch();
  }

  Future<Folder?> getFolder(String path) {
    return (select(
      folders,
    )..where((f) => f.path.equals(path))).getSingleOrNull();
  }

  Stream<Folder?> watchFolder(String path) {
    return (select(
      folders,
    )..where((f) => f.path.equals(path))).watchSingleOrNull();
  }

  Future<void> updateFolderFollowStatus(
    String path,
    String status, {
    bool? isBiometricLocked,
    String? biography,
  }) async {
    await (update(folders)..where((f) => f.path.equals(path))).write(
      FoldersCompanion(
        followStatus: Value(status),
        isBiometricLocked: isBiometricLocked != null
            ? Value(isBiometricLocked)
            : const Value.absent(),
        biography: biography != null ? Value(biography) : const Value.absent(),
      ),
    );
  }

  Future<void> bulkUpdateFollowStatus(
    List<String> paths,
    String status, {
    bool clearBiometric = false,
  }) async {
    await (update(folders)..where((f) => f.path.isIn(paths))).write(
      FoldersCompanion(
        followStatus: Value(status),
        isBiometricLocked: clearBiometric
            ? const Value(false)
            : const Value.absent(),
      ),
    );
  }

  Future<List<MediaRow>> getHomeFeedMediaPage({
    required int limit,
    required int offset,
  }) async {
    final rows = await customSelect(
      '''
      SELECT * FROM (
        SELECT m.*,
          ROW_NUMBER() OVER (
            PARTITION BY m.folder_path
            ORDER BY COALESCE(m.date_taken, m.date_modified) DESC, m.id DESC
          ) AS rn
        FROM media_items m
        INNER JOIN folders f ON m.folder_path = f.path
        WHERE f.follow_status = 'HOME_FEED'
          AND f.is_biometric_locked = 0
          AND m.is_trashed = 0
      )
      WHERE rn = 1
      ORDER BY COALESCE(date_taken, date_modified) DESC, id DESC
      LIMIT ? OFFSET ?
      ''',
      variables: [Variable.withInt(limit), Variable.withInt(offset)],
      readsFrom: {mediaItems, folders},
    ).get();
    return rows.map(_mediaFromQuery).toList();
  }

  Future<List<MediaRow>> getExploreMediaPage({
    required int limit,
    required int offset,
  }) async {
    final rows = await customSelect(
      '''
      SELECT m.* FROM media_items m
      INNER JOIN folders f ON m.folder_path = f.path
      WHERE f.follow_status = 'HOME_FEED'
        AND f.is_biometric_locked = 0
        AND m.is_trashed = 0
      ORDER BY m.date_modified DESC
      LIMIT ? OFFSET ?
      ''',
      variables: [Variable.withInt(limit), Variable.withInt(offset)],
      readsFrom: {mediaItems, folders},
    ).get();
    return rows.map(_mediaFromQuery).toList();
  }

  Future<List<MediaRow>> searchExploreMedia(
    String query, {
    required int limit,
    required int offset,
  }) {
    return searchExploreMediaFiltered(
      text: query,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<MediaRow>> searchExploreMediaFiltered({
    String text = '',
    String? label,
    String? color,
    required int limit,
    required int offset,
  }) async {
    final trimmedText = text.trim().toLowerCase();
    final trimmedLabel = label?.trim().toLowerCase();
    final trimmedColor = color?.trim().toLowerCase();

    final textPattern = '%$trimmedText%';
    final labelPattern = trimmedLabel == null || trimmedLabel.isEmpty
        ? null
        : '%$trimmedLabel%';
    final hasText = trimmedText.isNotEmpty;
    final hasLabel = labelPattern != null;
    final hasColor = trimmedColor != null && trimmedColor.isNotEmpty;

    final rows = await customSelect(
      '''
      SELECT m.* FROM media_items m
      INNER JOIN folders f ON m.folder_path = f.path
      LEFT JOIN media_analysis_cache a ON a.media_id = m.id
      WHERE f.follow_status != 'UNFOLLOWED'
        AND f.is_biometric_locked = 0
        AND m.is_trashed = 0
        AND (
          ? = 0
          OR LOWER(m.display_name) LIKE ?
          OR LOWER(m.folder_name) LIKE ?
          OR LOWER(f.name) LIKE ?
          OR LOWER(m.folder_path) LIKE ?
          OR LOWER(m.mime_type) LIKE ?
          OR LOWER(a.labels_json) LIKE ?
        )
        AND (
          ? = 0
          OR LOWER(a.labels_json) LIKE ?
        )
        AND (
          ? = 0
          OR a.dominant_color = ?
        )
      ORDER BY m.date_modified DESC
      LIMIT ? OFFSET ?
      ''',
      variables: [
        Variable.withInt(hasText ? 1 : 0),
        Variable.withString(textPattern),
        Variable.withString(textPattern),
        Variable.withString(textPattern),
        Variable.withString(textPattern),
        Variable.withString(textPattern),
        Variable.withString(textPattern),
        Variable.withInt(hasLabel ? 1 : 0),
        Variable.withString(labelPattern ?? ''),
        Variable.withInt(hasColor ? 1 : 0),
        Variable.withString(trimmedColor ?? ''),
        Variable.withInt(limit),
        Variable.withInt(offset),
      ],
      readsFrom: {mediaItems, folders, mediaAnalysisCache},
    ).get();
    return rows.map(_mediaFromQuery).toList();
  }

  Future<List<MediaRow>> getAllSearchableMedia() async {
    final rows = await customSelect(
      '''
      SELECT m.* FROM media_items m
      INNER JOIN folders f ON m.folder_path = f.path
      WHERE f.follow_status != 'UNFOLLOWED'
        AND f.is_biometric_locked = 0
        AND m.is_trashed = 0
      ORDER BY m.date_modified DESC
      ''',
      readsFrom: {mediaItems, folders},
    ).get();
    return rows.map(_mediaFromQuery).toList();
  }

  Stream<List<MediaRow>> watchFavoritesMedia() {
    final query = '''
      SELECT m.* FROM media_items m
      INNER JOIN folders f ON m.folder_path = f.path
      WHERE m.is_favorite = 1
        AND f.follow_status = 'HOME_FEED'
        AND f.is_biometric_locked = 0
        AND m.is_trashed = 0
      ORDER BY m.date_modified DESC
      ''';
    return customSelect(
      query,
      readsFrom: {mediaItems, folders},
    ).watch().map((rows) => rows.map(_mediaFromQuery).toList());
  }

  Stream<List<MediaRow>> watchMediaInFolder(String folderPath) {
    return (select(mediaItems)
          ..where(
            (m) => m.folderPath.equals(folderPath) & m.isTrashed.equals(false),
          )
          ..orderBy([(m) => OrderingTerm.desc(m.dateModified)]))
        .watch();
  }

  Future<void> setFavorite(int id, bool isFavorite) {
    return (update(mediaItems)..where((m) => m.id.equals(id))).write(
      MediaItemsCompanion(isFavorite: Value(isFavorite)),
    );
  }

  Future<void> deleteMediaByIds(List<int> ids) {
    return (delete(mediaItems)..where((m) => m.id.isIn(ids))).go();
  }

  Future<List<MediaRow>> getPotentialDuplicateMedia() async {
    final rows = await customSelect(
      '''
      SELECT m.* FROM media_items m
      INNER JOIN folders f ON m.folder_path = f.path
      WHERE f.follow_status = 'HOME_FEED'
        AND f.is_biometric_locked = 0
        AND m.is_trashed = 0
        AND (
          (m.size, COALESCE(m.width, -1), COALESCE(m.height, -1)) IN (
            SELECT size, COALESCE(width, -1), COALESCE(height, -1)
            FROM media_items m2
            INNER JOIN folders f2 ON m2.folder_path = f2.path
            WHERE f2.follow_status = 'HOME_FEED'
              AND f2.is_biometric_locked = 0
              AND m2.is_trashed = 0
            GROUP BY size, COALESCE(width, -1), COALESCE(height, -1)
            HAVING COUNT(*) > 1
          )
          OR (
            m.width IS NOT NULL
            AND m.height IS NOT NULL
            AND (COALESCE(m.width, -1), COALESCE(m.height, -1)) IN (
              SELECT COALESCE(width, -1), COALESCE(height, -1)
              FROM media_items m3
              INNER JOIN folders f3 ON m3.folder_path = f3.path
              WHERE f3.follow_status = 'HOME_FEED'
                AND f3.is_biometric_locked = 0
                AND m3.is_trashed = 0
                AND m3.width IS NOT NULL
                AND m3.height IS NOT NULL
              GROUP BY COALESCE(width, -1), COALESCE(height, -1)
              HAVING COUNT(*) > 1
            )
          )
        )
      ORDER BY m.size DESC, COALESCE(m.width, -1) DESC, COALESCE(m.height, -1) DESC,
        m.date_modified DESC
      ''',
      readsFrom: {mediaItems, folders},
    ).get();
    return rows.map(_mediaFromQuery).toList();
  }

  Future<List<MediaRow>> getHomeFeedImagesMissingDimensions() async {
    final rows = await customSelect(
      '''
      SELECT m.* FROM media_items m
      INNER JOIN folders f ON m.folder_path = f.path
      WHERE f.follow_status = 'HOME_FEED'
        AND f.is_biometric_locked = 0
        AND m.is_trashed = 0
        AND m.mime_type LIKE 'image/%'
        AND (m.width IS NULL OR m.height IS NULL)
      ''',
      readsFrom: {mediaItems, folders},
    ).get();
    return rows.map(_mediaFromQuery).toList();
  }

  Future<void> updateMediaDimensions(int id, int width, int height) {
    return (update(mediaItems)..where((m) => m.id.equals(id))).write(
      MediaItemsCompanion(
        width: Value(width),
        height: Value(height),
      ),
    );
  }

  Future<List<MediaRow>> getHomeFeedImagesMissingLocation() async {
    final rows = await customSelect(
      '''
      SELECT m.* FROM media_items m
      INNER JOIN folders f ON m.folder_path = f.path
      WHERE f.follow_status = 'HOME_FEED'
        AND f.is_biometric_locked = 0
        AND m.is_trashed = 0
        AND m.mime_type LIKE 'image/%'
        AND (
          m.latitude IS NULL OR m.longitude IS NULL
          OR m.latitude = 0 OR m.longitude = 0
        )
      ORDER BY m.date_modified DESC
      ''',
      readsFrom: {mediaItems, folders},
    ).get();
    return rows.map(_mediaFromQuery).toList();
  }

  Future<void> updateMediaLocation(int id, double latitude, double longitude) {
    return (update(mediaItems)..where((m) => m.id.equals(id))).write(
      MediaItemsCompanion(
        latitude: Value(latitude),
        longitude: Value(longitude),
      ),
    );
  }

  Future<void> replaceAllMedia(List<MediaItemsCompanion> items) async {
    await syncMediaItems(items, preserveIds: const {});
  }

  Future<void> syncMediaItems(
    List<MediaItemsCompanion> items, {
    required Set<int> preserveIds,
  }) async {
    await transaction(() async {
      final scannedIds = items.map((row) => row.id.value).toSet();
      final keepIds = {...scannedIds, ...preserveIds};

      if (items.isNotEmpty) {
        await batch((b) {
          for (final row in items) {
            b.insert(mediaItems, row, mode: InsertMode.insertOrReplace);
          }
        });
      }

      if (keepIds.isEmpty) {
        await delete(mediaItems).go();
        return;
      }

      await (delete(mediaItems)..where((m) => m.id.isNotIn(keepIds.toList())))
          .go();
    });
  }

  Future<void> upsertFolders(List<FoldersCompanion> folderRows) async {
    await transaction(() async {
      for (final row in folderRows) {
        final existing = await getFolder(row.path.value);
        await into(folders).insert(
          FoldersCompanion(
            path: row.path,
            name: row.name,
            mediaCount: row.mediaCount,
            lastModified: row.lastModified,
            // Auto covers come from repairFolderCovers(), not photo_manager.
            coverImageUri: existing != null
                ? Value(existing.coverImageUri)
                : const Value.absent(),
            followStatus: row.followStatus,
            customCoverUri: existing != null
                ? Value(existing.customCoverUri)
                : const Value.absent(),
            showInStories: existing != null
                ? Value(existing.showInStories)
                : const Value.absent(),
            isBiometricLocked: existing != null
                ? Value(existing.isBiometricLocked)
                : const Value.absent(),
            biography: existing?.biography != null
                ? Value(existing!.biography)
                : const Value.absent(),
            isHidden: existing != null
                ? Value(existing.isHidden)
                : const Value.absent(),
            isPinned: existing != null
                ? Value(existing.isPinned)
                : const Value.absent(),
            sortOrder: existing != null
                ? Value(existing.sortOrder)
                : const Value.absent(),
            storyLastViewedTime: existing != null
                ? Value(existing.storyLastViewedTime)
                : const Value.absent(),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> updateFolderCounts() async {
    await customStatement('''
      UPDATE folders SET media_count = (
        SELECT COUNT(*) FROM media_items
        WHERE media_items.folder_path = folders.path
          AND media_items.is_trashed = 0
      )
    ''');
  }

  Future<void> repairFolderCovers() async {
    if (!usesFilesystemGallery) {
      await customStatement('''
        UPDATE folders SET custom_cover_uri = NULL
        WHERE custom_cover_uri IS NOT NULL
          AND (custom_cover_uri LIKE '/%' OR custom_cover_uri LIKE 'file://%')
      ''');
      await customStatement('''
        UPDATE folders SET cover_image_uri = NULL
        WHERE cover_image_uri IS NOT NULL
          AND (cover_image_uri LIKE '/%' OR cover_image_uri LIKE 'file://%')
      ''');
    }

    await customStatement('''
      UPDATE folders SET custom_cover_uri = NULL
      WHERE custom_cover_uri IS NOT NULL
        AND NOT EXISTS (
          SELECT 1 FROM media_items
          WHERE media_items.folder_path = folders.path
            AND media_items.uri = folders.custom_cover_uri
            AND media_items.is_trashed = 0
        )
    ''');

    await updateFolderAutoCovers();
  }

  Future<void> updateFolderAutoCovers() async {
    await customStatement('''
      UPDATE folders SET cover_image_uri = (
        SELECT uri FROM media_items
        WHERE media_items.folder_path = folders.path
          AND media_items.is_trashed = 0
        ORDER BY COALESCE(date_taken, date_modified, date_added) DESC
        LIMIT 1
      )
    ''');
  }

  Future<void> updateFolderAutoCover(String path) {
    return customStatement(
      '''
      UPDATE folders SET cover_image_uri = (
        SELECT uri FROM media_items
        WHERE media_items.folder_path = folders.path
          AND media_items.is_trashed = 0
        ORDER BY COALESCE(date_taken, date_modified, date_added) DESC
        LIMIT 1
      )
      WHERE path = ?
      ''',
      [path],
    );
  }

  Future<void> setFolderCustomCover(String path, String? coverUri) async {
    await (update(folders)..where((f) => f.path.equals(path))).write(
      FoldersCompanion(customCoverUri: Value(coverUri)),
    );
    if (coverUri == null) {
      await updateFolderAutoCover(path);
    }
  }

  Future<List<Folder>> getStoriesEnabledFolders() {
    return (select(folders)
          ..where(
            (f) =>
                f.showInStories.equals(true) &
                f.isBiometricLocked.equals(false) &
                f.followStatus.equals('HOME_FEED'),
          )
          ..orderBy([(f) => OrderingTerm.asc(f.name)]))
        .get();
  }

  Future<List<MediaRow>> getMediaAddedAfter(int timestampMs) async {
    final rows =
        await (select(mediaItems)
              ..where(
                (m) =>
                    m.dateAdded.isBiggerOrEqualValue(timestampMs) &
                    m.isTrashed.equals(false),
              )
              ..orderBy([(m) => OrderingTerm.desc(m.dateAdded)]))
            .get();
    return rows;
  }

  Future<List<Folder>> searchFolders(String query) async {
    final pattern = '%${query.toLowerCase()}%';
    return (select(folders)
          ..where(
            (f) =>
                f.followStatus.equals('UNFOLLOWED').not() &
                f.mediaCount.isBiggerThanValue(0) &
                (f.name.lower().like(pattern) | f.path.lower().like(pattern)),
          )
          ..orderBy([
            (f) => OrderingTerm.desc(f.mediaCount),
            (f) => OrderingTerm.asc(f.name),
          ])
          ..limit(12))
        .get();
  }

  MediaRow _mediaFromQuery(QueryRow row) {
    return MediaRow(
      id: row.read<int>('id'),
      uri: row.read<String>('uri'),
      displayName: row.read<String>('display_name'),
      folderName: row.read<String>('folder_name'),
      folderPath: row.read<String>('folder_path'),
      dateAdded: row.read<int>('date_added'),
      dateModified: row.read<int>('date_modified'),
      dateTaken: row.readNullable<int>('date_taken'),
      size: row.read<int>('size'),
      mimeType: row.read<String>('mime_type'),
      width: row.readNullable<int>('width'),
      height: row.readNullable<int>('height'),
      latitude: row.readNullable<double>('latitude'),
      longitude: row.readNullable<double>('longitude'),
      cameraMake: row.readNullable<String>('camera_make'),
      cameraModel: row.readNullable<String>('camera_model'),
      iso: row.readNullable<int>('iso'),
      shutterSpeed: row.readNullable<String>('shutter_speed'),
      focalLength: row.readNullable<double>('focal_length'),
      aperture: row.readNullable<String>('aperture'),
      isFavorite: row.read<bool>('is_favorite'),
      thumbnailUri: row.readNullable<String>('thumbnail_uri'),
      videoDuration: row.readNullable<int>('video_duration'),
      lastViewedAt: row.readNullable<int>('last_viewed_at'),
      backupState: row.read<int>('backup_state'),
      lastSyncTime: row.readNullable<int>('last_sync_time'),
      isTrashed: row.read<bool>('is_trashed'),
      trashedAt: row.readNullable<int>('trashed_at'),
      originalPath: row.readNullable<String>('original_path'),
    );
  }

  Future<List<MediaRow>> getOrganizeMediaPool() async {
    final rows = await customSelect(
      '''
      SELECT m.* FROM media_items m
      INNER JOIN folders f ON m.folder_path = f.path
      WHERE f.follow_status = 'HOME_FEED'
        AND f.is_biometric_locked = 0
        AND m.is_trashed = 0
      ORDER BY m.date_modified DESC
      ''',
      readsFrom: {mediaItems, folders},
    ).get();
    return rows.map(_mediaFromQuery).toList();
  }

  Future<List<MediaRow>> getAllHomeFeedMedia() async {
    return getOrganizeMediaPool();
  }

  Future<List<MediaRow>> getFavoriteMediaList() async {
    final rows = await customSelect(
      '''
      SELECT m.* FROM media_items m
      INNER JOIN folders f ON m.folder_path = f.path
      WHERE m.is_favorite = 1
        AND f.follow_status = 'HOME_FEED'
        AND f.is_biometric_locked = 0
        AND m.is_trashed = 0
      ORDER BY m.date_modified DESC
      ''',
      readsFrom: {mediaItems, folders},
    ).get();
    return rows.map(_mediaFromQuery).toList();
  }

  Future<MediaAnalysisRow?> getAnalysisForMedia(int mediaId) {
    return (select(mediaAnalysisCache)
          ..where((a) => a.mediaId.equals(mediaId)))
        .getSingleOrNull();
  }

  Future<List<MediaAnalysisRow>> getAllAnalysisRows() {
    return select(mediaAnalysisCache).get();
  }

  Future<void> upsertAnalysisRow(MediaAnalysisCacheCompanion row) {
    return into(mediaAnalysisCache).insert(row, mode: InsertMode.replace);
  }

  Future<void> upsertAnalysisRows(List<MediaAnalysisCacheCompanion> rows) async {
    await batch((b) {
      for (final row in rows) {
        b.insert(mediaAnalysisCache, row, mode: InsertMode.replace);
      }
    });
  }

  Future<int> getAnalysisCount() async {
    final count = mediaAnalysisCache.mediaId.count();
    final query = selectOnly(mediaAnalysisCache)..addColumns([count]);
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<List<MediaRow>> getMediaWithLocation() async {
    final rows = await customSelect(
      '''
      SELECT m.* FROM media_items m
      INNER JOIN folders f ON m.folder_path = f.path
      WHERE f.follow_status = 'HOME_FEED'
        AND f.is_biometric_locked = 0
        AND m.is_trashed = 0
        AND m.latitude IS NOT NULL AND m.longitude IS NOT NULL
        AND m.latitude != 0 AND m.longitude != 0
      ORDER BY m.date_modified DESC
      ''',
      readsFrom: {mediaItems, folders},
    ).get();
    return rows.map(_mediaFromQuery).toList();
  }

  Future<LocationPlaceRow?> getCachedPlace(String placeKey) {
    return (select(locationPlaceCache)
          ..where((p) => p.placeKey.equals(placeKey)))
        .getSingleOrNull();
  }

  Future<List<LocationPlaceRow>> getAllCachedPlaces() {
    return select(locationPlaceCache).get();
  }

  Future<void> upsertPlace(LocationPlaceCacheCompanion row) {
    return into(locationPlaceCache).insert(row, mode: InsertMode.replace);
  }

  // --- NEW WORK: Move, Trash, Restore operations ---

  Future<void> moveMediaItems(
    List<int> ids,
    String targetFolderPath,
    String targetFolderName,
  ) async {
    await (update(mediaItems)..where((m) => m.id.isIn(ids))).write(
      MediaItemsCompanion(
        folderPath: Value(targetFolderPath),
        folderName: Value(targetFolderName),
      ),
    );
    await updateFolderCounts();
  }

  Stream<List<MediaRow>> watchTrashedMedia() {
    return (select(mediaItems)
          ..where((m) => m.isTrashed.equals(true))
          ..orderBy([(m) => OrderingTerm.desc(m.trashedAt)]))
        .watch();
  }

  Future<void> trashMediaItems(
    List<int> ids,
    int trashedAtTime,
    Map<int, String> origPaths,
  ) async {
    await transaction(() async {
      for (final id in ids) {
        final path = origPaths[id];
        await (update(mediaItems)..where((m) => m.id.equals(id))).write(
          MediaItemsCompanion(
            isTrashed: const Value(true),
            trashedAt: Value(trashedAtTime),
            originalPath: path != null ? Value(path) : const Value.absent(),
          ),
        );
      }
    });
    await updateFolderCounts();
  }

  Future<void> restoreMediaItems(List<int> ids) async {
    await (update(mediaItems)..where((m) => m.id.isIn(ids))).write(
      const MediaItemsCompanion(
        isTrashed: Value(false),
        trashedAt: Value.absent(),
        originalPath: Value.absent(),
      ),
    );
    await updateFolderCounts();
  }

  Future<List<MediaRow>> getExpiredTrashedMedia(int beforeTimestamp) {
    return (select(mediaItems)..where(
          (m) =>
              m.isTrashed.equals(true) &
              m.trashedAt.isSmallerThanValue(beforeTimestamp),
        ))
        .get();
  }

  Future<void> updateFolderStories(String path, bool showInStories) async {
    await (update(folders)..where((f) => f.path.equals(path))).write(
      FoldersCompanion(showInStories: Value(showInStories)),
    );
  }

  Stream<List<TravelMode>> watchAllTravelModes() {
    return (select(
      travelModes,
    )..orderBy([(t) => OrderingTerm.desc(t.startDate)])).watch();
  }

  Stream<TravelMode?> watchActiveTravelMode() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (select(travelModes)
          ..where(
            (t) =>
                t.startDate.isSmallerOrEqualValue(now) &
                t.endDate.isBiggerOrEqualValue(now),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.startDate)])
          ..limit(1))
        .watchSingleOrNull();
  }

  Future<TravelMode?> getTravelModeById(String id) {
    return (select(
      travelModes,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> insertTravelMode(TravelModesCompanion row) {
    return into(travelModes).insert(row, mode: InsertMode.replace);
  }

  Future<void> updateTravelMode(TravelModesCompanion row) {
    return update(travelModes).replace(row);
  }

  Future<void> deleteTravelMode(String id) {
    return (delete(travelModes)..where((t) => t.id.equals(id))).go();
  }

  Future<List<MediaRow>> getMediaPendingBackup({int limit = 100}) async {
    final rows = await customSelect(
      '''
      SELECT m.* FROM media_items m
      WHERE m.is_trashed = 0
        AND m.backup_state IN (0, 3)
      ORDER BY m.date_added ASC
      LIMIT ?
      ''',
      variables: [Variable<int>(limit)],
      readsFrom: {mediaItems},
    ).get();
    return rows.map(_mediaFromQuery).toList();
  }

  Future<List<({MediaRow row, bool isVault})>> getMediaPendingBackupWithFolder({
    int limit = 100,
  }) async {
    final rows = await customSelect(
      '''
      SELECT m.*,
        CASE
          WHEN f.is_biometric_locked = 1 AND f.follow_status = 'ACCOUNT_ONLY'
          THEN 1 ELSE 0
        END AS is_vault
      FROM media_items m
      LEFT JOIN folders f ON m.folder_path = f.path
      WHERE m.is_trashed = 0
        AND m.backup_state IN (0, 3)
      ORDER BY m.date_added ASC
      LIMIT ?
      ''',
      variables: [Variable<int>(limit)],
      readsFrom: {mediaItems, folders},
    ).get();
    return rows
        .map(
          (row) => (
            row: _mediaFromQuery(row),
            isVault: row.read<int>('is_vault') == 1,
          ),
        )
        .toList();
  }

  Future<bool> hasPendingVaultBackup() async {
    final row = await customSelect(
      '''
      SELECT COUNT(*) AS vault_count
      FROM media_items m
      INNER JOIN folders f ON m.folder_path = f.path
      WHERE m.is_trashed = 0
        AND m.backup_state IN (0, 3)
        AND f.is_biometric_locked = 1
        AND f.follow_status = 'ACCOUNT_ONLY'
      ''',
      readsFrom: {mediaItems, folders},
    ).getSingle();
    return row.read<int>('vault_count') > 0;
  }

  Future<int> countMediaPendingBackup() async {
    final row = await customSelect(
      '''
      SELECT COUNT(*) AS pending_count FROM media_items
      WHERE is_trashed = 0
        AND backup_state IN (0, 3)
      ''',
      readsFrom: {mediaItems},
    ).getSingle();
    return row.read<int>('pending_count');
  }

  Future<void> updateMediaBackupState(int id, int backupState) async {
    await (update(mediaItems)..where((m) => m.id.equals(id))).write(
      MediaItemsCompanion(backupState: Value(backupState)),
    );
  }

  Future<void> markMediaBackedUp(int id, int syncedAtMs) async {
    await (update(mediaItems)..where((m) => m.id.equals(id))).write(
      MediaItemsCompanion(
        backupState: const Value(1),
        lastSyncTime: Value(syncedAtMs),
      ),
    );
  }

  Future<void> resetStaleBackupInProgress() async {
    await (update(mediaItems)..where((m) => m.backupState.equals(2))).write(
      const MediaItemsCompanion(backupState: Value(3)),
    );
  }

  Future<List<MediaRow>> getBackedUpMediaSample({
    required int offset,
    required int limit,
  }) async {
    final rows = await customSelect(
      '''
      SELECT m.*,
        CASE
          WHEN f.is_biometric_locked = 1 AND f.follow_status = 'ACCOUNT_ONLY'
          THEN 1 ELSE 0
        END AS is_vault
      FROM media_items m
      LEFT JOIN folders f ON m.folder_path = f.path
      WHERE m.is_trashed = 0
        AND m.backup_state = 1
      ORDER BY m.last_sync_time ASC, m.id ASC
      LIMIT ? OFFSET ?
      ''',
      variables: [Variable<int>(limit), Variable<int>(offset)],
      readsFrom: {mediaItems, folders},
    ).get();
    return rows.map(_mediaFromQuery).toList();
  }

  Future<List<({MediaRow row, bool isVault})>> getBackedUpMediaSampleWithFolder({
    required int offset,
    required int limit,
  }) async {
    final rows = await customSelect(
      '''
      SELECT m.*,
        CASE
          WHEN f.is_biometric_locked = 1 AND f.follow_status = 'ACCOUNT_ONLY'
          THEN 1 ELSE 0
        END AS is_vault
      FROM media_items m
      LEFT JOIN folders f ON m.folder_path = f.path
      WHERE m.is_trashed = 0
        AND m.backup_state = 1
      ORDER BY m.last_sync_time ASC, m.id ASC
      LIMIT ? OFFSET ?
      ''',
      variables: [Variable<int>(limit), Variable<int>(offset)],
      readsFrom: {mediaItems, folders},
    ).get();
    return rows
        .map(
          (row) => (
            row: _mediaFromQuery(row),
            isVault: row.read<int>('is_vault') == 1,
          ),
        )
        .toList();
  }

  Future<int> countBackedUpMedia() async {
    final row = await customSelect(
      '''
      SELECT COUNT(*) AS backed_up_count FROM media_items
      WHERE is_trashed = 0
        AND backup_state = 1
      ''',
      readsFrom: {mediaItems},
    ).getSingle();
    return row.read<int>('backed_up_count');
  }

  Future<void> markMediaIdsBackedUp(Iterable<int> ids, int syncedAtMs) async {
    final idList = ids.toList();
    if (idList.isEmpty) return;
    await (update(mediaItems)..where((m) => m.id.isIn(idList))).write(
      MediaItemsCompanion(
        backupState: const Value(1),
        lastSyncTime: Value(syncedAtMs),
      ),
    );
  }

  Future<void> markMediaIdsPending(Iterable<int> ids) async {
    final idList = ids.toList();
    if (idList.isEmpty) return;
    await (update(mediaItems)..where((m) => m.id.isIn(idList))).write(
      const MediaItemsCompanion(backupState: Value(0)),
    );
  }
}
