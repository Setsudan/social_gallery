import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_gallery/data/local/app_database.dart';
import 'package:social_gallery/domain/models/backup_state.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('getMediaPendingBackup returns pending and failed items only', () async {
    await db.into(db.mediaItems).insert(
      MediaItemsCompanion.insert(
        id: const Value(1),
        uri: 'a',
        displayName: 'a.jpg',
        folderName: 'Camera',
        folderPath: '/camera',
        dateAdded: 1,
        dateModified: 1,
        size: 100,
        mimeType: 'image/jpeg',
        backupState: const Value(0),
      ),
    );
    await db.into(db.mediaItems).insert(
      MediaItemsCompanion.insert(
        id: const Value(2),
        uri: 'b',
        displayName: 'b.jpg',
        folderName: 'Camera',
        folderPath: '/camera',
        dateAdded: 2,
        dateModified: 2,
        size: 100,
        mimeType: 'image/jpeg',
        backupState: const Value(1),
      ),
    );
    await db.into(db.mediaItems).insert(
      MediaItemsCompanion.insert(
        id: const Value(3),
        uri: 'c',
        displayName: 'c.jpg',
        folderName: 'Camera',
        folderPath: '/camera',
        dateAdded: 3,
        dateModified: 3,
        size: 100,
        mimeType: 'image/jpeg',
        backupState: const Value(3),
      ),
    );
    await db.into(db.mediaItems).insert(
      MediaItemsCompanion.insert(
        id: const Value(4),
        uri: 'd',
        displayName: 'd.jpg',
        folderName: 'Camera',
        folderPath: '/camera',
        dateAdded: 4,
        dateModified: 4,
        size: 100,
        mimeType: 'image/jpeg',
        backupState: const Value(0),
        isTrashed: const Value(true),
      ),
    );

    final pending = await db.getMediaPendingBackup();
    expect(pending.map((row) => row.id).toList(), [1, 3]);
  });

  test('resetStaleBackupInProgress marks in-progress rows as failed', () async {
    await db.into(db.mediaItems).insert(
      MediaItemsCompanion.insert(
        id: const Value(10),
        uri: 'x',
        displayName: 'x.jpg',
        folderName: 'Camera',
        folderPath: '/camera',
        dateAdded: 1,
        dateModified: 1,
        size: 100,
        mimeType: 'image/jpeg',
        backupState: const Value(2),
      ),
    );

    await db.resetStaleBackupInProgress();
    final row = await (db.select(db.mediaItems)
          ..where((m) => m.id.equals(10)))
        .getSingle();

    expect(row.backupState, MediaBackupState.failed.value);
  });

  test('getBackedUpMediaSample returns backed up rows only', () async {
    await db.into(db.mediaItems).insert(
      MediaItemsCompanion.insert(
        id: const Value(20),
        uri: 'a',
        displayName: 'a.jpg',
        folderName: 'Camera',
        folderPath: '/camera',
        dateAdded: 1,
        dateModified: 1,
        size: 100,
        mimeType: 'image/jpeg',
        backupState: const Value(1),
        lastSyncTime: const Value(200),
      ),
    );
    await db.into(db.mediaItems).insert(
      MediaItemsCompanion.insert(
        id: const Value(21),
        uri: 'b',
        displayName: 'b.jpg',
        folderName: 'Camera',
        folderPath: '/camera',
        dateAdded: 2,
        dateModified: 2,
        size: 100,
        mimeType: 'image/jpeg',
        backupState: const Value(0),
      ),
    );

    final sample = await db.getBackedUpMediaSample(offset: 0, limit: 10);
    expect(sample.map((row) => row.id).toList(), [20]);
    expect(await db.countBackedUpMedia(), 1);
  });
}
