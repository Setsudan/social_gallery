import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_gallery/core/backup/backup_protocol.dart';
import 'package:social_gallery/core/backup/desktop_backup_server.dart';
import 'package:social_gallery/core/backup/pairing_service.dart';
import 'package:social_gallery/data/repositories/preferences_repository.dart';

void main() {
  late Directory tempDir;
  late PairingService pairing;
  late DesktopBackupServer server;
  late String token;
  late int port;
  late List<bool> receivingStates;
  late List<int> completedCounts;
  late List<String?> receivedFileNames;
  late List<int> receivedByteCounts;
  late List<int> receivedByteTotals;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('backup_receiving_test_');
    SharedPreferences.setMockInitialValues({});
    final prefs = PreferencesRepository(await SharedPreferences.getInstance());
    pairing = PairingService(prefs);
    token = pairing.createToken();
    await prefs.setBackupAuthToken(token);
    receivingStates = [];
    completedCounts = [];
    receivedFileNames = [];
    receivedByteCounts = [];
    receivedByteTotals = [];

    server = DesktopBackupServer(
      pairing: pairing,
      deviceName: 'TestDesktop',
      backupRoot: tempDir.path,
      onReceivingStateChanged: (
        receiving,
        completedCount, {
        currentFileName,
        int bytesReceived = 0,
        int bytesTotal = 0,
      }) {
        receivingStates.add(receiving);
        completedCounts.add(completedCount);
        receivedFileNames.add(currentFileName);
        receivedByteCounts.add(bytesReceived);
        receivedByteTotals.add(bytesTotal);
      },
    );
    await server.start();
    port = server.port!;
  });

  tearDown(() async {
    await server.stop();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Map<String, String> authHeaders() => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  Future<String> hashBytes(List<int> bytes) async {
    final digest = await sha256.bind(Stream.value(bytes)).first;
    return digest.toString();
  }

  Future<http.Response> postJson(String path, Map<String, dynamic> body) {
    return http.post(
      Uri.http('127.0.0.1:$port', path),
      headers: authHeaders(),
      body: jsonEncode(body),
    );
  }

  test('receiving callback activates on backup init with open session', () async {
    final bytes = [1, 2, 3, 4];
    final checksum = await hashBytes(bytes);

    final initResponse = await postJson('/v1/backup/init', {
      'items': [
        {
          'id': 42,
          'checksum': checksum,
          'folderName': 'Camera',
          'name': 'photo.jpg',
          'mime': 'image/jpeg',
          'size': bytes.length,
        },
      ],
    });

    expect(initResponse.statusCode, 200);
    expect(server.isReceivingBackup, isTrue);
    expect(receivingStates, contains(true));
    expect(receivedFileNames.any((name) => name == 'Camera/photo.jpg'), isTrue);

    final initBody = BackupProtocol.decodeJson(initResponse.body);
    final sessionId = initBody['sessions'][0]['sessionId'] as String;
    expect(sessionId.startsWith('exists-'), isFalse);
  });

  test('receiving callback reports byte progress on chunk upload', () async {
    final bytes = List<int>.generate(8192, (index) => index % 256);
    final checksum = await hashBytes(bytes);

    final initResponse = await postJson('/v1/backup/init', {
      'items': [
        {
          'id': 77,
          'checksum': checksum,
          'folderName': 'Camera',
          'name': 'large.jpg',
          'mime': 'image/jpeg',
          'size': bytes.length,
        },
      ],
    });
    final initBody = BackupProtocol.decodeJson(initResponse.body);
    final sessionId = initBody['sessions'][0]['sessionId'] as String;

    final chunkResponse = await http.put(
      Uri.http('127.0.0.1:$port', '/v1/backup/chunk/$sessionId'),
      headers: {'Authorization': 'Bearer $token'},
      body: bytes,
    );
    expect(chunkResponse.statusCode, 200);
    expect(receivedByteCounts.any((value) => value == bytes.length), isTrue);
    expect(receivedByteTotals.any((value) => value == bytes.length), isTrue);
  });

  test('receiving callback ends after complete and idle timeout', () async {
    final bytes = [9, 8, 7];
    final checksum = await hashBytes(bytes);

    final initResponse = await postJson('/v1/backup/init', {
      'items': [
        {
          'id': 55,
          'checksum': checksum,
          'folderName': 'Camera',
          'name': 'done.jpg',
          'mime': 'image/jpeg',
          'size': bytes.length,
        },
      ],
    });
    final initBody = BackupProtocol.decodeJson(initResponse.body);
    final sessionId = initBody['sessions'][0]['sessionId'] as String;

    final chunkResponse = await http.put(
      Uri.http('127.0.0.1:$port', '/v1/backup/chunk/$sessionId'),
      headers: {'Authorization': 'Bearer $token'},
      body: bytes,
    );
    expect(chunkResponse.statusCode, 200);

    final completeResponse = await postJson('/v1/backup/complete', {
      'sessionId': sessionId,
      'checksum': checksum,
    });
    expect(completeResponse.statusCode, 200);
    expect(server.receivingCompletedCount, 1);
    expect(completedCounts, contains(1));

    await Future<void>.delayed(const Duration(seconds: 6));
    expect(server.isReceivingBackup, isFalse);
    expect(receivingStates.last, isFalse);
  });

  test('expired upload sessions are cleaned up', () async {
    final bytes = [1, 2, 3];
    final checksum = await hashBytes(bytes);

    final initResponse = await postJson('/v1/backup/init', {
      'items': [
        {
          'id': 88,
          'checksum': checksum,
          'folderName': 'Camera',
          'name': 'stale.jpg',
          'mime': 'image/jpeg',
          'size': bytes.length,
        },
      ],
    });
    expect(initResponse.statusCode, 200);
    expect(server.isReceivingBackup, isTrue);

    await server.expireUploadSessionsForTest();
    await Future<void>.delayed(const Duration(seconds: 6));

    expect(server.isReceivingBackup, isFalse);
  });
}
