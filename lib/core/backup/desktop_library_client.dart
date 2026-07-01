import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:social_gallery/core/backup/backup_protocol.dart';

/// Mobile-side client for browsing and streaming from the desktop archive.
class DesktopLibraryClient {
  DesktopLibraryClient({
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

  Future<LibraryCatalogResponse?> fetchCatalog({
    int cursor = 0,
    int limit = 50,
    String? folderName,
  }) async {
    try {
      final query = {
        'cursor': '$cursor',
        'limit': '$limit',
        if (folderName != null && folderName.isNotEmpty)
          'folderName': folderName,
      };
      final response = await _http
          .get(_uri('/v1/library/catalog', query), headers: _headers)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) return null;
      return LibraryCatalogResponse.fromJson(
        BackupProtocol.decodeJson(response.body),
      );
    } catch (e) {
      debugPrint('Library catalog failed: $e');
      return null;
    }
  }

  Future<VaultUnlockResponse?> unlockVault(String password) async {
    try {
      final response = await _http
          .post(
            _uri('/v1/library/vault/unlock'),
            headers: _headers,
            body: BackupProtocol.encodeJson(
              VaultUnlockRequest(password: password).toJson(),
            ),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;
      return VaultUnlockResponse.fromJson(
        BackupProtocol.decodeJson(response.body),
      );
    } catch (e) {
      debugPrint('Vault unlock failed: $e');
      return null;
    }
  }

  Future<List<int>?> fetchThumbnail(int mediaId, {String? vaultToken}) async {
    try {
      final query = {
        if (vaultToken != null) 'vaultToken': vaultToken,
      };
      final response = await _http
          .get(_uri('/v1/library/thumbnail/$mediaId', query), headers: _headers)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) return null;
      return response.bodyBytes;
    } catch (e) {
      debugPrint('Thumbnail fetch failed: $e');
      return null;
    }
  }

  Future<LibraryStreamInitResponse?> initStream({
    required int mediaId,
    String? vaultToken,
  }) async {
    try {
      final response = await _http
          .post(
            _uri('/v1/library/stream/init'),
            headers: _headers,
            body: BackupProtocol.encodeJson(
              LibraryStreamInitRequest(
                mediaId: mediaId,
                vaultToken: vaultToken,
              ).toJson(),
            ),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) return null;
      return LibraryStreamInitResponse.fromJson(
        BackupProtocol.decodeJson(response.body),
      );
    } catch (e) {
      debugPrint('Stream init failed: $e');
      return null;
    }
  }

  Future<List<int>?> fetchStreamChunk({
    required String sessionId,
    int start = 0,
    int? end,
  }) async {
    try {
      final headers = {
        'Authorization': 'Bearer $authToken',
        if (end != null) 'Range': 'bytes=$start-$end',
      };
      final response = await _http
          .get(_uri('/v1/library/stream/chunk/$sessionId'), headers: headers)
          .timeout(const Duration(minutes: 5));
      if (response.statusCode != 200 && response.statusCode != 206) return null;
      return response.bodyBytes;
    } catch (e) {
      debugPrint('Stream chunk failed: $e');
      return null;
    }
  }

  Future<File?> downloadToTempFile({
    required String sessionId,
    required int totalSize,
    void Function(int downloaded)? onProgress,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/desktop_stream_$sessionId.bin');
    final sink = file.openWrite(mode: FileMode.writeOnly);

    var downloaded = 0;
    while (downloaded < totalSize) {
      final end = (downloaded + BackupProtocol.chunkSize - 1).clamp(
        downloaded,
        totalSize - 1,
      );
      final chunk = await fetchStreamChunk(
        sessionId: sessionId,
        start: downloaded,
        end: end,
      );
      if (chunk == null || chunk.isEmpty) {
        await sink.close();
        if (await file.exists()) await file.delete();
        return null;
      }
      sink.add(chunk);
      downloaded += chunk.length;
      onProgress?.call(downloaded);
    }

    await sink.close();
    return file;
  }
}
