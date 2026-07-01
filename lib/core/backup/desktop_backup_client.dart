import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:photo_manager/photo_manager.dart';
import 'package:social_gallery/core/backup/backup_protocol.dart';
import 'package:social_gallery/domain/models/media_item.dart';

/// Mobile-side client for uploading media to the desktop backup server.
class DesktopBackupClient {
  DesktopBackupClient({
    required this.host,
    required this.port,
    required this.authToken,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String host;
  final int port;
  final String authToken;
  final http.Client _http;

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.http('$host:$port', path, query);

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $authToken',
    'Content-Type': 'application/json',
  };

  void close() => _http.close();

  Future<HealthResponse?> health() async {
    try {
      final response = await _http
          .get(_uri('/v1/health'), headers: _headers)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;
      return HealthResponse.fromJson(BackupProtocol.decodeJson(response.body));
    } catch (e) {
      debugPrint('Health request failed: $e');
      return null;
    }
  }

  Future<bool> unpair() async {
    try {
      final response = await _http
          .post(_uri('/v1/unpair'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Unpair request failed: $e');
      return false;
    }
  }

  Future<PairResponse?> pair({
    required String pin,
    required String deviceName,
  }) async {
    try {
      final response = await _http
          .post(
            _uri('/v1/pair'),
            headers: {'Content-Type': 'application/json'},
            body: BackupProtocol.encodeJson(
              PairRequest(pin: pin, deviceName: deviceName).toJson(),
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;
      return PairResponse.fromJson(BackupProtocol.decodeJson(response.body));
    } catch (e) {
      debugPrint('Pair request failed: $e');
      return null;
    }
  }

  Future<bool> registerVaultPassword(String password) async {
    try {
      final response = await _http
          .post(
            _uri('/v1/vault/register'),
            headers: _headers,
            body: BackupProtocol.encodeJson(
              VaultRegisterRequest(password: password).toJson(),
            ),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return false;
      final body = BackupProtocol.decodeJson(response.body);
      return VaultRegisterResponse.fromJson(body).success;
    } catch (e) {
      debugPrint('Vault register failed: $e');
      return false;
    }
  }

  Future<BackupInitResponse?> initBackup(List<BackupInitItem> items) async {
    try {
      final response = await _http
          .post(
            _uri('/v1/backup/init'),
            headers: _headers,
            body: BackupProtocol.encodeJson({
              'items': items.map((i) => i.toJson()).toList(),
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) return null;
      return BackupInitResponse.fromJson(
        BackupProtocol.decodeJson(response.body),
      );
    } catch (e) {
      debugPrint('Backup init failed: $e');
      return null;
    }
  }

  Future<BackupReconcileResponse?> reconcileItems(
    List<BackupReconcileItem> items,
  ) async {
    if (items.isEmpty) {
      return const BackupReconcileResponse(results: []);
    }

    try {
      final response = await _http
          .post(
            _uri('/v1/backup/reconcile'),
            headers: _headers,
            body: BackupProtocol.encodeJson({
              'items': items.map((i) => i.toJson()).toList(),
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) return null;
      return BackupReconcileResponse.fromJson(
        BackupProtocol.decodeJson(response.body),
      );
    } catch (e) {
      debugPrint('Backup reconcile failed: $e');
      return null;
    }
  }

  Future<BackupVerifyResponse?> verifyItems(
    List<BackupReconcileItem> items,
  ) async {
    if (items.isEmpty) {
      return const BackupVerifyResponse(results: []);
    }

    try {
      final response = await _http
          .post(
            _uri('/v1/backup/verify'),
            headers: _headers,
            body: BackupProtocol.encodeJson({
              'items': items.map((i) => i.toJson()).toList(),
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) return null;
      return BackupVerifyResponse.fromJson(
        BackupProtocol.decodeJson(response.body),
      );
    } catch (e) {
      debugPrint('Backup verify failed: $e');
      return null;
    }
  }

  Future<bool> uploadChunk(String sessionId, List<int> bytes) async {
    try {
      final response = await _http
          .put(
            _uri('/v1/backup/chunk/$sessionId'),
            headers: {
              'Authorization': 'Bearer $authToken',
              'Content-Type': 'application/octet-stream',
            },
            body: bytes,
          )
          .timeout(const Duration(minutes: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Chunk upload failed: $e');
      return false;
    }
  }

  Future<BackupCompleteResponse?> completeUpload({
    required String sessionId,
    required String checksum,
  }) async {
    try {
      final response = await _http
          .post(
            _uri('/v1/backup/complete'),
            headers: _headers,
            body: BackupProtocol.encodeJson(
              BackupCompleteRequest(sessionId: sessionId, checksum: checksum)
                  .toJson(),
            ),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) return null;
      return BackupCompleteResponse.fromJson(
        BackupProtocol.decodeJson(response.body),
      );
    } catch (e) {
      debugPrint('Backup complete failed: $e');
      return null;
    }
  }

  Future<File?> _openMediaFile(MediaItem item) async {
    try {
      final entity = await AssetEntity.fromId(item.uri);
      if (entity == null) return null;
      return await entity.originFile ?? await entity.loadFile(isOrigin: true);
    } catch (e) {
      debugPrint('Failed to open media ${item.id}: $e');
      return null;
    }
  }

  Future<String?> computeChecksum(MediaItem item) async {
    final file = await _openMediaFile(item);
    if (file == null) return null;
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  Future<bool> uploadMediaItem(MediaItem item) async {
    final file = await _openMediaFile(item);
    if (file == null) return false;

    final size = await file.length();
    final checksumDigest = await sha256.bind(file.openRead()).first;
    final checksum = checksumDigest.toString();

    final init = await initBackup([
      BackupInitItem(
        id: item.id,
        name: item.displayName,
        folderName: item.folderName,
        size: size,
        mime: item.mimeType,
        checksum: checksum,
        dateTaken: item.dateTaken,
        dateModified: item.dateModified,
        dateAdded: item.dateAdded,
        latitude: item.latitude,
        longitude: item.longitude,
        isVault: item.isVault,
      ),
    ]);

    if (init == null || init.sessions.isEmpty) return false;

    final session = init.sessions.first;
    if (session.alreadyExists) {
      final complete = await completeUpload(
        sessionId: session.sessionId,
        checksum: checksum,
      );
      return complete?.matchesAck(mediaId: item.id, checksum: checksum) ?? false;
    }

    final stream = file.openRead();
    var buffer = <int>[];
    await for (final bytes in stream) {
      buffer.addAll(bytes);
      while (buffer.length >= BackupProtocol.chunkSize) {
        final chunk = buffer.sublist(0, BackupProtocol.chunkSize);
        buffer = buffer.sublist(BackupProtocol.chunkSize);
        final ok = await uploadChunk(session.sessionId, chunk);
        if (!ok) return false;
      }
    }
    if (buffer.isNotEmpty) {
      final ok = await uploadChunk(session.sessionId, buffer);
      if (!ok) return false;
    }

    final complete = await completeUpload(
      sessionId: session.sessionId,
      checksum: checksum,
    );
    return complete?.matchesAck(mediaId: item.id, checksum: checksum) ?? false;
  }
}
