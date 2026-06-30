import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_gallery/core/backup/backup_protocol.dart';
import 'package:social_gallery/core/backup/desktop_backup_inventory.dart';
import 'package:social_gallery/core/backup/desktop_backup_server.dart';
import 'package:social_gallery/core/backup/pairing_service.dart';
import 'package:social_gallery/data/repositories/preferences_repository.dart';

void main() {
  late Directory tempDir;
  late PreferencesRepository prefs;
  late PairingService pairing;
  late DesktopBackupServer server;
  late String token;
  late int port;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('backup_server_test_');
    SharedPreferences.setMockInitialValues({});
    prefs = PreferencesRepository(await SharedPreferences.getInstance());
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

  Future<String> writeBackedUpFile({
    required String folder,
    required String name,
    required List<int> bytes,
  }) async {
    final path = p.join(tempDir.path, folder, name);
    await File(path).parent.create(recursive: true);
    await File(path).writeAsBytes(bytes);
    return path;
  }

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

  test('reconcile returns present when inventory has mediaId', () async {
    final bytes = [10, 20, 30];
    final checksum = await hashBytes(bytes);
    await server.inventory.upsert(
      BackupInventoryEntry(
        mediaId: 7,
        checksum: checksum,
        relativePath: 'Camera/a.jpg',
        folderName: 'Camera',
        fileName: 'a.jpg',
      ),
    );

    final response = await postJson('/v1/backup/reconcile', {
      'items': [
        {
          'id': 7,
          'checksum': checksum,
          'folderName': 'Camera',
          'name': 'a.jpg',
        },
      ],
    });

    expect(response.statusCode, 200);
    final parsed = BackupReconcileResponse.fromJson(
      BackupProtocol.decodeJson(response.body),
    );
    expect(parsed.results.single.status, BackupReconcileStatus.present);
  });

  test('reconcile returns present for canonical path match', () async {
    final bytes = [4, 5, 6];
    final checksum = await hashBytes(bytes);
    await writeBackedUpFile(folder: 'Camera', name: 'b.jpg', bytes: bytes);

    final response = await postJson('/v1/backup/reconcile', {
      'items': [
        {
          'id': 8,
          'checksum': checksum,
          'folderName': 'Camera',
          'name': 'b.jpg',
        },
      ],
    });

    expect(response.statusCode, 200);
    final parsed = BackupReconcileResponse.fromJson(
      BackupProtocol.decodeJson(response.body),
    );
    expect(parsed.results.single.status, BackupReconcileStatus.present);
    expect(server.inventory.lookup(8)?.checksum, checksum);
  });

  test('reconcile returns missing when file is absent', () async {
    final response = await postJson('/v1/backup/reconcile', {
      'items': [
        {
          'id': 9,
          'checksum': 'deadbeef',
          'folderName': 'Camera',
          'name': 'missing.jpg',
        },
      ],
    });

    expect(response.statusCode, 200);
    final parsed = BackupReconcileResponse.fromJson(
      BackupProtocol.decodeJson(response.body),
    );
    expect(parsed.results.single.status, BackupReconcileStatus.missing);
  });

  test('reconcile returns mismatch when checksum differs', () async {
    final bytes = [1, 1, 1];
    await writeBackedUpFile(folder: 'Camera', name: 'c.jpg', bytes: bytes);

    final response = await postJson('/v1/backup/reconcile', {
      'items': [
        {
          'id': 10,
          'checksum': 'different',
          'folderName': 'Camera',
          'name': 'c.jpg',
        },
      ],
    });

    expect(response.statusCode, 200);
    final parsed = BackupReconcileResponse.fromJson(
      BackupProtocol.decodeJson(response.body),
    );
    expect(parsed.results.single.status, BackupReconcileStatus.mismatch);
  });

  test('complete response includes mediaId and checksum ack', () async {
    final response = await postJson('/v1/backup/complete', {
      'sessionId': 'exists-15',
      'checksum': 'ignored',
    });

    expect(response.statusCode, 200);
    final parsed = BackupCompleteResponse.fromJson(
      BackupProtocol.decodeJson(response.body),
    );
    expect(parsed.success, isTrue);
    expect(parsed.mediaId, 15);
    expect(parsed.checksum, 'ignored');
  });
}
