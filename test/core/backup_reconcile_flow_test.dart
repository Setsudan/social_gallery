import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_gallery/core/backup/backup_protocol.dart';
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

  Future<void> insertMedia({
    required int id,
    required int backupState,
    int lastSyncTime = 0,
  }) async {
    await db.into(db.mediaItems).insert(
      MediaItemsCompanion.insert(
        id: Value(id),
        uri: 'uri-$id',
        displayName: 'photo$id.jpg',
        folderName: 'Camera',
        folderPath: '/camera',
        dateAdded: id,
        dateModified: id,
        size: 100,
        mimeType: 'image/jpeg',
        backupState: Value(backupState),
        lastSyncTime: Value(lastSyncTime),
      ),
    );
  }

  test('reconcile present marks backed up and mismatch resets pending', () async {
    await insertMedia(id: 1, backupState: MediaBackupState.pending.value);
    await insertMedia(id: 2, backupState: MediaBackupState.failed.value);

    await db.markMediaIdsBackedUp([1], 1000);
    await db.markMediaIdsPending([2]);

    final row1 = await (db.select(db.mediaItems)
          ..where((m) => m.id.equals(1)))
        .getSingle();
    final row2 = await (db.select(db.mediaItems)
          ..where((m) => m.id.equals(2)))
        .getSingle();

    expect(row1.backupState, MediaBackupState.backedUp.value);
    expect(row2.backupState, MediaBackupState.pending.value);
  });

  test('verify missing resets backed up rows to pending', () async {
    await insertMedia(
      id: 5,
      backupState: MediaBackupState.backedUp.value,
      lastSyncTime: 500,
    );

    await db.markMediaIdsPending([5]);

    final row = await (db.select(db.mediaItems)
          ..where((m) => m.id.equals(5)))
        .getSingle();
    expect(row.backupState, MediaBackupState.pending.value);
  });

  test('getBackedUpMediaSample returns rows ordered by last sync time', () async {
    await insertMedia(
      id: 1,
      backupState: MediaBackupState.backedUp.value,
      lastSyncTime: 300,
    );
    await insertMedia(
      id: 2,
      backupState: MediaBackupState.backedUp.value,
      lastSyncTime: 100,
    );
    await insertMedia(id: 3, backupState: MediaBackupState.pending.value);

    final sample = await db.getBackedUpMediaSample(offset: 0, limit: 10);
    expect(sample.map((row) => row.id).toList(), [2, 1]);
  });

  test('BackupCompleteResponse matches ack only when mediaId and checksum align',
      () {
    const ack = BackupCompleteResponse(
      success: true,
      mediaId: 3,
      checksum: 'abc',
    );

    expect(ack.matchesAck(mediaId: 3, checksum: 'abc'), isTrue);
    expect(ack.matchesAck(mediaId: 4, checksum: 'abc'), isFalse);
    expect(ack.matchesAck(mediaId: 3, checksum: 'xyz'), isFalse);
  });
}
