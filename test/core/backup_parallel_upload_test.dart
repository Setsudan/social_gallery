import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_gallery/core/backup/backup_concurrency.dart';
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
    tempDir = await Directory.systemTemp.createTemp('backup_parallel_test_');
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

  test('parallel uploads store all files with matching checksums', () async {
    final uploads = <({MediaItem item, File file, List<int> bytes})>[];

    for (var index = 0; index < 5; index++) {
      final bytes = List<int>.generate(
        4000 + index * 500,
        (byteIndex) => (byteIndex + index) % 256,
      );
      final name = 'photo$index.jpg';
      final file = File('${tempDir.path}/$name');
      await file.writeAsBytes(bytes);
      uploads.add((
        item: _testItem(id: 200 + index, name: name, size: bytes.length),
        file: file,
        bytes: bytes,
      ));
    }

    var peakInFlight = 0;
    var inFlight = 0;

    final results = await runWithConcurrency(
      items: uploads,
      concurrency: 3,
      task: (upload, _) async {
        inFlight++;
        peakInFlight = inFlight > peakInFlight ? inFlight : peakInFlight;
        try {
          return await client.uploadFile(upload.item, upload.file);
        } finally {
          inFlight--;
        }
      },
    );

    expect(results.where((result) => result == true).length, uploads.length);
    expect(peakInFlight, lessThanOrEqualTo(3));
    expect(peakInFlight, greaterThan(1));

    for (final upload in uploads) {
      final saved = File('${tempDir.path}/Camera/${upload.item.displayName}');
      expect(await saved.exists(), isTrue);
      final digest = await sha256.bind(saved.openRead()).first;
      final expected = await sha256.bind(Stream.value(upload.bytes)).first;
      expect(digest.toString(), expected.toString());
    }
  });
}
