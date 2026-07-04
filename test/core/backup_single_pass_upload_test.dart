import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_gallery/core/backup/backup_protocol.dart';
import 'package:social_gallery/core/backup/desktop_backup_client.dart';
import 'package:social_gallery/core/backup/desktop_backup_server.dart';
import 'package:social_gallery/core/backup/pairing_service.dart';
import 'package:social_gallery/data/repositories/preferences_repository.dart';
import 'package:social_gallery/domain/models/media_item.dart';

MediaItem _testItem({required int id, required String name, required int size}) {
  return MediaItem(
    id: id,
    uri: 'test://$id',
    displayName: name,
    folderName: 'Camera',
    folderPath: '/Camera',
    mimeType: 'image/jpeg',
    dateTaken: 1704067200000,
    dateModified: 1704067200000,
    dateAdded: 1704067200000,
    width: 100,
    height: 100,
    size: size,
  );
}

void main() {
  late Directory tempDir;
  late PairingService pairing;
  late DesktopBackupServer server;
  late DesktopBackupClient client;
  late String token;
  late int port;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('backup_single_pass_test_');
    SharedPreferences.setMockInitialValues({});
    final prefs = PreferencesRepository(await SharedPreferences.getInstance());
    pairing = PairingService(prefs);
    token = pairing.createToken();
    await prefs.setBackupAuthToken(token);

    server = DesktopBackupServer(
      pairing: pairing,
      deviceName: 'TestDesktop',
      backupRoot: tempDir.path,
    );
    await server.start();
    port = server.port!;

    client = DesktopBackupClient(
      host: '127.0.0.1',
      port: port,
      authToken: token,
    );
  });

  tearDown(() async {
    client.close();
    await server.stop();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('checksum cache skips stale entries after metadata change', () {
    final cache = BackupSessionChecksumCache();
    final item = _testItem(id: 1, name: 'a.jpg', size: 100);
    cache.put(item, 'abc');

    expect(cache.lookup(item), 'abc');
    expect(cache.lookup(_testItem(id: 1, name: 'a.jpg', size: 101)), isNull);
  });

  test('prepared upload skips init and completes with cached checksum', () async {
    final bytes = List<int>.generate(9000, (index) => index % 256);
    final file = File('${tempDir.path}/cached.jpg');
    await file.writeAsBytes(bytes);
    final checksum = (await sha256.bind(file.openRead()).first).toString();

    final item = _testItem(id: 301, name: 'cached.jpg', size: bytes.length);
    final init = await client.initBackup([
      BackupInitItem(
        id: item.id,
        name: item.displayName,
        folderName: item.folderName,
        size: item.size,
        mime: item.mimeType,
        checksum: checksum,
      ),
    ]);
    expect(init, isNotNull);
    expect(init!.sessions, hasLength(1));

    final session = BackupUploadSession(
      sessionId: init.sessions.first.sessionId,
      alreadyExists: init.sessions.first.alreadyExists,
    );

    final success = await client.uploadPreparedFile(
      item,
      file,
      checksum: checksum,
      uploadSession: session,
    );

    expect(success, isTrue);

    final saved = File('${tempDir.path}/Camera/cached.jpg');
    expect(await saved.exists(), isTrue);
  });

  test('batch init accepts multiple items in one request', () async {
    final uploads = <({MediaItem item, File file, String checksum})>[];

    for (var index = 0; index < 3; index++) {
      final bytes = List<int>.generate(100 + index, (i) => (i + index) % 256);
      final name = 'batch$index.jpg';
      final file = File('${tempDir.path}/$name');
      await file.writeAsBytes(bytes);
      final checksum = (await sha256.bind(file.openRead()).first).toString();
      uploads.add((
        item: _testItem(id: 400 + index, name: name, size: bytes.length),
        file: file,
        checksum: checksum,
      ));
    }

    final init = await client.initBackup(
      uploads
          .map(
            (upload) => BackupInitItem(
              id: upload.item.id,
              name: upload.item.displayName,
              folderName: upload.item.folderName,
              size: upload.item.size,
              mime: upload.item.mimeType,
              checksum: upload.checksum,
            ),
          )
          .toList(),
    );

    expect(init?.sessions.length, uploads.length);
  });
}
