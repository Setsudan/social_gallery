import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/folders_table.dart';
import 'tables/media_items_table.dart';
import 'tables/travel_modes_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Folders, MediaItems, TravelModes])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

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
  }) async {
    final pattern = '%${query.toLowerCase()}%';
    final rows = await customSelect(
      '''
      SELECT m.* FROM media_items m
      INNER JOIN folders f ON m.folder_path = f.path
      WHERE f.follow_status = 'HOME_FEED'
        AND f.is_biometric_locked = 0
        AND m.is_trashed = 0
        AND (
          LOWER(m.display_name) LIKE ?
          OR LOWER(m.folder_name) LIKE ?
        )
      ORDER BY m.date_modified DESC
      LIMIT ? OFFSET ?
      ''',
      variables: [
        Variable.withString(pattern),
        Variable.withString(pattern),
        Variable.withInt(limit),
        Variable.withInt(offset),
      ],
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
        AND (m.size, COALESCE(m.width, -1), COALESCE(m.height, -1)) IN (
        SELECT size, COALESCE(width, -1), COALESCE(height, -1)
        FROM media_items m2
        INNER JOIN folders f2 ON m2.folder_path = f2.path
        WHERE f2.follow_status = 'HOME_FEED'
        AND f2.is_biometric_locked = 0
        AND m2.is_trashed = 0
        GROUP BY size, COALESCE(width, -1), COALESCE(height, -1)
        HAVING COUNT(*) > 1
      )
      ORDER BY m.size DESC, COALESCE(m.width, -1) DESC, COALESCE(m.height, -1) DESC,
        m.date_modified DESC
      ''',
      readsFrom: {mediaItems, folders},
    ).get();
    return rows.map(_mediaFromQuery).toList();
  }

  Future<void> replaceAllMedia(List<MediaItemsCompanion> items) async {
    await transaction(() async {
      await delete(mediaItems).go();
      if (items.isNotEmpty) {
        await batch((b) {
          b.insertAll(mediaItems, items);
        });
      }
    });
  }

  Future<void> upsertFolders(List<FoldersCompanion> folderRows) async {
    await batch((b) {
      for (final row in folderRows) {
        b.insert(folders, row, mode: InsertMode.insertOrReplace);
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
                f.name.lower().like(pattern) &
                f.followStatus.equals('UNFOLLOWED').not(),
          )
          ..orderBy([(f) => OrderingTerm.asc(f.name)])
          ..limit(8))
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
}
