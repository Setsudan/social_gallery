import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:social_gallery/core/backup/desktop_backup_inventory.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('backup_inventory_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<String> writeFile(String relativePath, List<int> bytes) async {
    final file = File(p.join(tempDir.path, relativePath));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<String> hashBytes(List<int> bytes) async {
    final digest = await sha256.bind(Stream.value(bytes)).first;
    return digest.toString();
  }

  test('backfillFromDisk indexes canonical path and checksum', () async {
    final bytes = [1, 2, 3, 4, 5];
    await writeFile('Camera/photo.jpg', bytes);
    final checksum = await hashBytes(bytes);

    final inventory = DesktopBackupInventory(backupRoot: tempDir.path);
    await inventory.backfillFromDisk();

    final entry = inventory.lookupByCanonicalPath('Camera', 'photo.jpg');
    expect(entry, isNotNull);
    expect(entry!.checksum, checksum);
    expect(entry.relativePath, 'Camera/photo.jpg');
    expect(entry.folderName, 'Camera');
    expect(entry.fileName, 'photo.jpg');
  });

  test('upsert persists mediaId lookup after load', () async {
    final inventory = DesktopBackupInventory(backupRoot: tempDir.path);
    await inventory.upsert(
      const BackupInventoryEntry(
        mediaId: 42,
        checksum: 'abc',
        relativePath: 'Camera/photo.jpg',
        folderName: 'Camera',
        fileName: 'photo.jpg',
        syncedAtMs: 1000,
      ),
    );

    final reloaded = DesktopBackupInventory(backupRoot: tempDir.path);
    await reloaded.load();

    expect(reloaded.lookup(42)?.checksum, 'abc');
    expect(
      reloaded.lookupByCanonicalPath('Camera', 'photo.jpg')?.mediaId,
      42,
    );
    expect(
      reloaded.lookupByChecksumInFolder('Camera', 'abc')?.mediaId,
      42,
    );
  });

  test('backfill skips hidden inventory directory', () async {
    await writeFile('.social_gallery/inventory.json', [123]);
    await writeFile('Camera/visible.jpg', [9, 9, 9]);

    final inventory = DesktopBackupInventory(backupRoot: tempDir.path);
    await inventory.backfillFromDisk();

    expect(inventory.lookupByCanonicalPath('.social_gallery', 'inventory.json'),
        isNull);
    expect(inventory.lookupByCanonicalPath('Camera', 'visible.jpg'), isNotNull);
  });
}
