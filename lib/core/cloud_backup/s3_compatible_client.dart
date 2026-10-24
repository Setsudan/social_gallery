import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:minio/io.dart';
import 'package:minio/minio.dart';
import 'package:social_gallery/core/cloud_backup/cloud_backup_config.dart';

typedef MultipartProgress = void Function(int bytesSent, int bytesTotal);

/// Thin wrapper over MinIO client for MinIO / RustFS / Cloudflare R2.
class S3CompatibleClient {
  S3CompatibleClient(this.config) : _minio = _build(config);

  final CloudBackupConfig config;
  final Minio _minio;

  static Minio _build(CloudBackupConfig config) {
    final uri = config.endpointUri;
    final endPoint = uri.hasPort
        ? '${uri.host}:${uri.port}'
        : uri.host;
    return Minio(
      endPoint: endPoint,
      accessKey: config.accessKey,
      secretKey: config.secretKey,
      useSSL: uri.scheme == 'https',
      region: config.region.isEmpty ? null : config.region,
      // Path-style for MinIO/RustFS; virtual-hosted often for R2.
      pathStyle: config.forcePathStyle,
    );
  }

  /// HEAD-equivalent / connectivity check.
  Future<bool> testConnection() async {
    try {
      await _minio.bucketExists(config.bucket).timeout(const Duration(seconds: 15));
      return true;
    } catch (e) {
      debugPrint('Cloud backup connection test failed: $e');
      return false;
    }
  }

  Future<bool> objectExists(String objectKey) async {
    try {
      await _minio.statObject(config.bucket, objectKey);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Uploads [filePath] with multipart under the hood via fPutObject.
  Future<void> uploadFile({
    required String objectKey,
    required String filePath,
    MultipartProgress? onProgress,
    String contentType = 'application/octet-stream',
  }) async {
    final total = await File(filePath).length();
    var lastSent = 0;
    await _minio.fPutObject(
      config.bucket,
      objectKey,
      filePath,
      metadata: {'content-type': contentType},
      onProgress: (sent) {
        lastSent = sent;
        onProgress?.call(sent, total);
      },
    );
    if (lastSent < total) {
      onProgress?.call(total, total);
    }
  }

  /// Uploads in-memory bytes (small objects / tests).
  Future<void> putBytes({
    required String objectKey,
    required Uint8List bytes,
    String contentType = 'application/octet-stream',
  }) async {
    await _minio.putObject(
      config.bucket,
      objectKey,
      Stream.value(bytes),
      size: bytes.length,
      metadata: {'content-type': contentType},
    );
  }

  Future<void> downloadFile({
    required String objectKey,
    required String outputPath,
  }) async {
    await _minio.fGetObject(config.bucket, objectKey, outputPath);
  }

  Future<void> deleteObject(String objectKey) async {
    await _minio.removeObject(config.bucket, objectKey);
  }
}
