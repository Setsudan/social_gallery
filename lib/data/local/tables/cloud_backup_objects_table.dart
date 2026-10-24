import 'package:drift/drift.dart';

/// Local map of cloud-backed objects (avoids listing the whole bucket each sync).
class CloudBackupObjects extends Table {
  IntColumn get mediaId => integer()();
  TextColumn get objectKey => text()();
  TextColumn get plaintextChecksum => text()();
  IntColumn get size => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {mediaId};
}
