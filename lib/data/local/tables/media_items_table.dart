import 'package:drift/drift.dart';

/// Drift table for indexed photos and videos mirrored from the device library.
@DataClassName('MediaRow')
@TableIndex.sql('''
  CREATE INDEX media_items_folder_trashed_modified
  ON media_items (folder_path, is_trashed, date_modified DESC)
''')
@TableIndex.sql('''
  CREATE INDEX media_items_favorite_trashed_modified
  ON media_items (is_trashed, is_favorite, date_modified DESC)
''')
@TableIndex.sql('''
  CREATE INDEX media_items_trashed_modified
  ON media_items (is_trashed, date_modified DESC)
''')
@TableIndex(name: 'media_items_backup_state', columns: {#backupState})
class MediaItems extends Table {
  IntColumn get id => integer()();
  TextColumn get uri => text()();
  TextColumn get displayName => text()();
  TextColumn get folderName => text()();
  TextColumn get folderPath => text()();
  IntColumn get dateAdded => integer()();
  IntColumn get dateModified => integer()();
  IntColumn get dateTaken => integer().nullable()();
  IntColumn get size => integer()();
  TextColumn get mimeType => text()();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  TextColumn get cameraMake => text().nullable()();
  TextColumn get cameraModel => text().nullable()();
  IntColumn get iso => integer().nullable()();
  TextColumn get shutterSpeed => text().nullable()();
  RealColumn get focalLength => real().nullable()();
  TextColumn get aperture => text().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  TextColumn get thumbnailUri => text().nullable()();
  IntColumn get videoDuration => integer().nullable()();
  IntColumn get lastViewedAt => integer().nullable()();
  IntColumn get backupState => integer().withDefault(const Constant(0))();
  IntColumn get lastSyncTime => integer().nullable()();

  BoolColumn get isTrashed => boolean().withDefault(const Constant(false))();
  IntColumn get trashedAt => integer().nullable()();
  TextColumn get originalPath => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
