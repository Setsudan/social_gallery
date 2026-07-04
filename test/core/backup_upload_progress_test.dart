import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
    tempDir = await Directory.systemTemp.createTemp('backup_upload_test_');
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

  test('upload progress callback reports preparing uploading completing', () async {
    final bytes = List<int>.generate(9000, (index) => index % 256);
    final file = File('${tempDir.path}/photo.jpg');
    await file.writeAsBytes(bytes);

    final phases = <BackupUploadPhase>[];
    final progressValues = <int>[];

    final item = _testItem(id: 101, name: 'photo.jpg', size: bytes.length);
    final success = await client.uploadFile(
      item,
      file,
      onProgress: ({
        required phase,
        required bytesSent,
        required bytesTotal,
      }) {
        phases.add(phase);
        progressValues.add(bytesSent);
      },
    );

    expect(success, isTrue);
    expect(phases.first, BackupUploadPhase.preparing);
    expect(phases, contains(BackupUploadPhase.uploading));
    expect(phases.last, BackupUploadPhase.completing);
    expect(progressValues.last, bytes.length);

    final saved = File('${tempDir.path}/Camera/photo.jpg');
    expect(await saved.exists(), isTrue);
    final digest = await sha256.bind(saved.openRead()).first;
    expect(digest.toString(), isNotEmpty);
  });

  test('chunk upload retries then succeeds after transient failure', () async {
    final bytes = [5, 6, 7, 8];
    final file = File('${tempDir.path}/retry.jpg');
    await file.writeAsBytes(bytes);

    var chunkAttempts = 0;
    final blockingClient = http.Client();
    final proxy = _RetryOnceClient(
      inner: blockingClient,
      host: '127.0.0.1',
      port: port,
      token: token,
      failFirstChunkAttempts: 1,
      onChunkAttempt: () => chunkAttempts++,
    );

    final retryClient = DesktopBackupClient(
      host: '127.0.0.1',
      port: port,
      authToken: token,
      httpClient: proxy,
    );

    final item = _testItem(id: 102, name: 'retry.jpg', size: bytes.length);
    final success = await retryClient.uploadFile(item, file);

    retryClient.close();
    expect(success, isTrue);
    expect(chunkAttempts, greaterThan(1));
  });
}

class _RetryOnceClient extends http.BaseClient {
  _RetryOnceClient({
    required this.inner,
    required this.host,
    required this.port,
    required this.token,
    required this.failFirstChunkAttempts,
    required this.onChunkAttempt,
  });

  final http.Client inner;
  final String host;
  final int port;
  final String token;
  final int failFirstChunkAttempts;
  final void Function() onChunkAttempt;
  var _failedChunks = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.method == 'PUT' &&
        request.url.path.contains('/v1/backup/chunk/')) {
      onChunkAttempt();
      if (_failedChunks < failFirstChunkAttempts) {
        _failedChunks++;
        return http.StreamedResponse(
          Stream.value(utf8.encode('fail')),
          500,
        );
      }
    }
    return inner.send(request);
  }

  @override
  void close() => inner.close();
}
