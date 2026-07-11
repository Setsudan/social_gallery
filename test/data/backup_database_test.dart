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

  test('getPendingBackupFolders orders by album age then pending size', () async {
    Future<void> insertMedia({
      required int id,
      required String folderName,
      required String folderPath,
      required int dateAdded,
      required int size,
      int backupState = 0,
    }) async {
      await db.into(db.mediaItems).insert(
        MediaItemsCompanion.insert(
          id: Value(id),
          uri: 'uri$id',
          displayName: '$id.jpg',
          folderName: folderName,
          folderPath: folderPath,
          dateAdded: dateAdded,
          dateModified: dateAdded,
          size: size,
          mimeType: 'image/jpeg',
          backupState: Value(backupState),
        ),
      );
    }

    await insertMedia(
      id: 1,
      folderName: 'OldLarge',
      folderPath: '/old-large',
      dateAdded: 100,
      size: 500_000_000,
    );
    await insertMedia(
      id: 2,
      folderName: 'OldLarge',
      folderPath: '/old-large',
      dateAdded: 200,
      size: 100,
      backupState: 1,
    );
    await insertMedia(
      id: 3,
      folderName: 'NewSmall',
      folderPath: '/new-small',
      dateAdded: 500,
      size: 50_000,
    );
    await insertMedia(
      id: 4,
      folderName: 'OldSmall',
      folderPath: '/old-small',
      dateAdded: 150,
      size: 10_000,
    );
    await insertMedia(
      id: 5,
      folderName: 'OldSmall',
      folderPath: '/old-small',
      dateAdded: 160,
      size: 20_000,
      backupState: 1,
    );

    final folders = await db.getPendingBackupFolders();
    expect(folders.map((folder) => folder.folderPath).toList(), [
      '/old-large',
      '/old-small',
      '/new-small',
    ]);
    expect(folders[0].pendingBytes, 500_000_000);
    expect(folders[1].pendingBytes, 10_000);
    expect(folders[2].pendingBytes, 50_000);
  });

  test('getPendingBackupFolders prefers smaller pending folders at same album age',
      () async {
    Future<void> insertPending({
      required int id,
      required String folderPath,
      required String folderName,
      required int albumOldestDate,
      required int pendingSize,
    }) async {
      await db.into(db.mediaItems).insert(
        MediaItemsCompanion.insert(
          id: Value(id),
          uri: 'uri$id',
          displayName: '$id.jpg',
          folderName: folderName,
          folderPath: folderPath,
          dateAdded: albumOldestDate,
          dateModified: albumOldestDate,
          size: pendingSize,
          mimeType: 'image/jpeg',
          backupState: const Value(0),
        ),
      );
    }

    await insertPending(
      id: 10,
      folderPath: '/b',
      folderName: 'B',
      albumOldestDate: 100,
      pendingSize: 1_000_000,
    );
    await insertPending(
      id: 11,
      folderPath: '/a',
      folderName: 'A',
      albumOldestDate: 100,
      pendingSize: 100,
    );

    final folders = await db.getPendingBackupFolders();
    expect(folders.map((folder) => folder.folderPath).toList(), ['/a', '/b']);
  });

  test('getMediaPendingBackup filters by folderPath', () async {
    Future<void> insertPending({
      required int id,
      required String folderPath,
      required String folderName,
      required int dateAdded,
    }) async {
      await db.into(db.mediaItems).insert(
        MediaItemsCompanion.insert(
          id: Value(id),
          uri: 'uri$id',
          displayName: '$id.jpg',
          folderName: folderName,
          folderPath: folderPath,
          dateAdded: dateAdded,
          dateModified: dateAdded,
          size: 100,
          mimeType: 'image/jpeg',
          backupState: const Value(0),
        ),
      );
    }

    await insertPending(
      id: 1,
      folderPath: '/camera',
      folderName: 'Camera',
      dateAdded: 2,
    );
    await insertPending(
      id: 2,
      folderPath: '/camera',
      folderName: 'Camera',
      dateAdded: 1,
    );
    await insertPending(
      id: 3,
      folderPath: '/downloads',
      folderName: 'Downloads',
      dateAdded: 3,
    );

    final cameraPending = await db.getMediaPendingBackup(folderPath: '/camera');
    expect(cameraPending.map((row) => row.id).toList(), [2, 1]);

    final downloadsPending =
        await db.getMediaPendingBackup(folderPath: '/downloads');
    expect(downloadsPending.map((row) => row.id).toList(), [3]);
  });

  test('countMediaPendingBackup filters by folderPath', () async {
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
        folderName: 'Downloads',
        folderPath: '/downloads',
        dateAdded: 2,
        dateModified: 2,
        size: 100,
        mimeType: 'image/jpeg',
        backupState: const Value(0),
      ),
    );

    expect(await db.countMediaPendingBackup(), 2);
    expect(await db.countMediaPendingBackup(folderPath: '/camera'), 1);
    expect(await db.countMediaPendingBackup(folderPath: '/downloads'), 1);
    expect(await db.countMediaPendingBackup(folderPath: '/missing'), 0);
  });
}
