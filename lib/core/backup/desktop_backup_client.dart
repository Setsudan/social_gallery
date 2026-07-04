import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:photo_manager/photo_manager.dart';
import 'package:social_gallery/core/backup/backup_checksum_cache.dart';
import 'package:social_gallery/core/backup/backup_protocol.dart';
import 'package:social_gallery/domain/models/media_item.dart';

export 'package:social_gallery/core/backup/backup_checksum_cache.dart';

/// Phase of a single-file upload on the mobile client.
enum BackupUploadPhase {
  preparing,
  uploading,
  completing,
}

typedef BackupUploadProgress = void Function({
  required BackupUploadPhase phase,
  required int bytesSent,
  required int bytesTotal,
});

typedef BackupUploadStallHandler = void Function(String fileName);

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

  static const _chunkTimeout = Duration(minutes: 3);
  static const _stallThreshold = Duration(seconds: 60);
  static const _maxChunkAttempts = 3;
  static const _preparingTimeout = Duration(minutes: 5);
  static const _maxChunksInFlight = 2;

  final Map<int, Future<File?>> _openFileCache = {};

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.http('$host:$port', path, query);

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $authToken',
    'Content-Type': 'application/json',
  };

  void close() {
    _openFileCache.clear();
    _http.close();
  }

  void clearOpenFileCache() => _openFileCache.clear();

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

  Future<bool> _uploadChunkWithRetry(
    String sessionId,
    List<int> bytes, {
    BackupUploadStallHandler? onStall,
    required String fileName,
  }) async {
    for (var attempt = 0; attempt < _maxChunkAttempts; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(
          Duration(seconds: attempt == 1 ? 2 : 5),
        );
      }

      var stallNotified = false;
      final stallTimer = Timer(_stallThreshold, () {
        if (!stallNotified) {
          stallNotified = true;
          onStall?.call(fileName);
        }
      });

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
            .timeout(_chunkTimeout);

        stallTimer.cancel();
        if (response.statusCode == 200) return true;
      } catch (e) {
        stallTimer.cancel();
        debugPrint(
          'Chunk upload failed (attempt ${attempt + 1}/$_maxChunkAttempts): $e',
        );
      }
    }
    return false;
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

  Future<File?> openMediaFile(MediaItem item) {
    return _openFileCache.putIfAbsent(item.id, () => _openMediaFile(item));
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
    final file = await openMediaFile(item);
    if (file == null) return null;
    return computeFileChecksum(file);
  }

  Future<String?> computeFileChecksum(
    File file, {
    int? size,
    BackupUploadProgress? onProgress,
  }) async {
    final totalSize = size ?? await file.length();
    try {
      final accumulator = _DigestAccumulator();
      final input = sha256.startChunkedConversion(accumulator);
      var bytesRead = 0;

      await for (final chunk in file.openRead().timeout(_preparingTimeout)) {
        input.add(chunk);
        bytesRead += chunk.length;
        onProgress?.call(
          phase: BackupUploadPhase.preparing,
          bytesSent: bytesRead,
          bytesTotal: totalSize,
        );
      }
      input.close();
      return accumulator.value?.toString();
    } catch (e) {
      debugPrint('Checksum computation failed: $e');
      return null;
    }
  }

  BackupInitItem _initItemFor(MediaItem item, int size, String checksum) {
    return BackupInitItem(
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
    );
  }

  Future<bool> uploadMediaItem(
    MediaItem item, {
    BackupUploadProgress? onProgress,
    BackupUploadStallHandler? onStall,
    String? knownChecksum,
    BackupUploadSession? uploadSession,
  }) async {
    final file = await openMediaFile(item);
    if (file == null) return false;
    return uploadFile(
      item,
      file,
      onProgress: onProgress,
      onStall: onStall,
      knownChecksum: knownChecksum,
      uploadSession: uploadSession,
    );
  }

  /// Uploads with a precomputed checksum and server session from batch init.
  Future<bool> uploadPreparedFile(
    MediaItem item,
    File file, {
    required String checksum,
    required BackupUploadSession uploadSession,
    BackupUploadProgress? onProgress,
    BackupUploadStallHandler? onStall,
  }) {
    return uploadFile(
      item,
      file,
      knownChecksum: checksum,
      uploadSession: uploadSession,
      onProgress: onProgress,
      onStall: onStall,
    );
  }

  /// Uploads an already-resolved file. For tests and [uploadMediaItem].
  Future<bool> uploadFile(
    MediaItem item,
    File file, {
    BackupUploadProgress? onProgress,
    BackupUploadStallHandler? onStall,
    String? knownChecksum,
    BackupUploadSession? uploadSession,
  }) async {
    final size = await file.length();
    final fileLabel = '${item.folderName}/${item.displayName}';

    onProgress?.call(
      phase: BackupUploadPhase.preparing,
      bytesSent: 0,
      bytesTotal: size,
    );

    var checksum = knownChecksum;
    var session = uploadSession;

    if (session == null) {
      if (checksum == null) {
        checksum = await computeFileChecksum(
          file,
          size: size,
          onProgress: onProgress,
        );
        if (checksum == null) return false;
      }

      final init = await initBackup([_initItemFor(item, size, checksum)]);
      if (init == null || init.sessions.isEmpty) return false;

      final initSession = init.sessions.first;
      session = BackupUploadSession(
        sessionId: initSession.sessionId,
        alreadyExists: initSession.alreadyExists,
      );
    } else if (checksum == null) {
      return false;
    }

    if (session.alreadyExists) {
      onProgress?.call(
        phase: BackupUploadPhase.completing,
        bytesSent: size,
        bytesTotal: size,
      );
      final complete = await completeUpload(
        sessionId: session.sessionId,
        checksum: checksum,
      );
      return complete?.matchesAck(mediaId: item.id, checksum: checksum) ?? false;
    }

    final uploaded = await _streamFileUpload(
      file: file,
      sessionId: session.sessionId,
      size: size,
      fileLabel: fileLabel,
      onProgress: onProgress,
      onStall: onStall,
    );
    if (!uploaded) return false;

    onProgress?.call(
      phase: BackupUploadPhase.completing,
      bytesSent: size,
      bytesTotal: size,
    );

    final complete = await completeUpload(
      sessionId: session.sessionId,
      checksum: checksum,
    );
    return complete?.matchesAck(mediaId: item.id, checksum: checksum) ?? false;
  }

  Future<bool> _streamFileUpload({
    required File file,
    required String sessionId,
    required int size,
    required String fileLabel,
    BackupUploadProgress? onProgress,
    BackupUploadStallHandler? onStall,
  }) async {
    var bytesSent = 0;
    onProgress?.call(
      phase: BackupUploadPhase.uploading,
      bytesSent: 0,
      bytesTotal: size,
    );

    final buffer = BytesBuilder(copy: false);
    final inFlight = <Future<bool>>[];

    Future<bool> drainInFlight({bool all = false}) async {
      while (inFlight.isNotEmpty &&
          (all || inFlight.length >= _maxChunksInFlight)) {
        final ok = await inFlight.removeAt(0);
        if (!ok) return false;
      }
      return true;
    }

    Future<bool> enqueueChunk(List<int> chunk) async {
      inFlight.add(
        _uploadChunkWithRetry(
          sessionId,
          chunk,
          onStall: onStall,
          fileName: fileLabel,
        ),
      );
      return drainInFlight();
    }

    try {
      await for (final bytes in file.openRead().timeout(_preparingTimeout)) {
        buffer.add(bytes);

        while (buffer.length >= BackupProtocol.chunkSize) {
          final chunk = _takeChunk(buffer, BackupProtocol.chunkSize);
          if (!await enqueueChunk(chunk)) return false;
          bytesSent += chunk.length;
          onProgress?.call(
            phase: BackupUploadPhase.uploading,
            bytesSent: bytesSent,
            bytesTotal: size,
          );
        }
      }

      if (buffer.length > 0) {
        final tail = buffer.takeBytes();
        if (!await enqueueChunk(tail)) return false;
        bytesSent += tail.length;
        onProgress?.call(
          phase: BackupUploadPhase.uploading,
          bytesSent: bytesSent,
          bytesTotal: size,
        );
      }

      return drainInFlight(all: true);
    } catch (e) {
      debugPrint('File upload stream failed: $e');
      return false;
    }
  }

  Uint8List _takeChunk(BytesBuilder buffer, int chunkSize) {
    final bytes = buffer.takeBytes();
    if (bytes.length <= chunkSize) {
      return Uint8List.fromList(bytes);
    }
    buffer.add(bytes.sublist(chunkSize));
    return Uint8List.fromList(bytes.sublist(0, chunkSize));
  }
}

class _DigestAccumulator implements Sink<Digest> {
  Digest? value;

  @override
  void add(Digest data) {
    value = data;
  }

  @override
  void close() {}
}
