import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:social_gallery/core/backup/backup_concurrency.dart';
import 'package:social_gallery/core/cloud_backup/cloud_backup_config.dart';
import 'package:social_gallery/core/cloud_backup/cloud_backup_inventory.dart';
import 'package:social_gallery/core/cloud_backup/cloud_credential_store.dart';
import 'package:social_gallery/core/cloud_backup/cloud_provider_preset.dart';
import 'package:social_gallery/core/cloud_backup/cloud_vault_key_store.dart';
import 'package:social_gallery/core/cloud_backup/s3_compatible_client.dart';
import 'package:social_gallery/core/cloud_backup/streaming_vault_cryptor.dart';
import 'package:social_gallery/core/notifications/cloud_backup_notification_service.dart';
import 'package:social_gallery/data/repositories/media_repository.dart';
import 'package:social_gallery/data/repositories/preferences_repository.dart';
import 'package:social_gallery/domain/models/backup_state.dart';
import 'package:social_gallery/domain/models/media_item.dart';

enum CloudBackupPhase {
  idle,
  needsConfig,
  needsPassword,
  checking,
  syncing,
  waitingForWifi,
  error,
}

class CloudBackupState {
  const CloudBackupState({
    this.phase = CloudBackupPhase.idle,
    this.enabled = false,
    this.processed = 0,
    this.total = 0,
    this.detail = '',
    this.errorMessage,
    this.lastBackupAt,
    this.bytesSent = 0,
    this.bytesTotal = 0,
    this.isRunning = false,
    this.needsPassword = false,
    this.provider = CloudBackupProvider.minio,
  });

  final CloudBackupPhase phase;
  final bool enabled;
  final int processed;
  final int total;
  final String detail;
  final String? errorMessage;
  final DateTime? lastBackupAt;
  final int bytesSent;
  final int bytesTotal;
  final bool isRunning;
  final bool needsPassword;
  final CloudBackupProvider provider;

  CloudBackupState copyWith({
    CloudBackupPhase? phase,
    bool? enabled,
    int? processed,
    int? total,
    String? detail,
    String? errorMessage,
    DateTime? lastBackupAt,
    int? bytesSent,
    int? bytesTotal,
    bool? isRunning,
    bool? needsPassword,
    CloudBackupProvider? provider,
    bool clearError = false,
  }) {
    return CloudBackupState(
      phase: phase ?? this.phase,
      enabled: enabled ?? this.enabled,
      processed: processed ?? this.processed,
      total: total ?? this.total,
      detail: detail ?? this.detail,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastBackupAt: lastBackupAt ?? this.lastBackupAt,
      bytesSent: bytesSent ?? this.bytesSent,
      bytesTotal: bytesTotal ?? this.bytesTotal,
      isRunning: isRunning ?? this.isRunning,
      needsPassword: needsPassword ?? this.needsPassword,
      provider: provider ?? this.provider,
    );
  }
}

/// Independent encrypted cloud backup sync (MinIO / RustFS / Cloudflare R2).
class CloudBackupController extends StateNotifier<CloudBackupState> {
  CloudBackupController(
    this._prefs,
    this._media,
    this._credentials,
    this._vaultKeys, {
    CloudBackupNotificationService? notifications,
    Connectivity? connectivity,
    this.isGallerySyncRunning,
    this.waitForGallerySync,
    this.onBackupFinished,
  })  : _notifications = notifications,
        _connectivity = connectivity ?? Connectivity(),
        _inventory = CloudBackupInventory(_media),
        _cryptor = StreamingVaultCryptor(),
        super(const CloudBackupState()) {
    _hydrate();
  }

  final PreferencesRepository _prefs;
  final MediaRepository _media;
  final CloudCredentialStore _credentials;
  final CloudVaultKeyStore _vaultKeys;
  final CloudBackupNotificationService? _notifications;
  final Connectivity _connectivity;
  final CloudBackupInventory _inventory;
  final StreamingVaultCryptor _cryptor;
  final bool Function()? isGallerySyncRunning;
  final Future<void> Function()? waitForGallerySync;
  final void Function()? onBackupFinished;

  static const _batchSize = 20;
  static const _imageConcurrency = 3;
  static const _largeFileBytes = 32 * 1024 * 1024;

  Timer? _heartbeat;
  var _runLock = false;

  void _hydrate() {
    state = state.copyWith(
      enabled: _prefs.cloudBackupEnabled,
      lastBackupAt: _prefs.lastCloudBackupAt,
      provider: CloudBackupProvider.fromId(_prefs.cloudBackupProvider),
      phase: _prefs.cloudBackupEnabled
          ? CloudBackupPhase.idle
          : CloudBackupPhase.idle,
    );
  }

  void startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 90), (_) {
      if (state.enabled && !state.isRunning) {
        unawaited(checkAndMaybeRun());
      }
    });
  }

  void stopHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = null;
  }

  @override
  void dispose() {
    stopHeartbeat();
    super.dispose();
  }

  Future<CloudBackupConfig?> loadConfig() async {
    final access = await _credentials.readAccessKey();
    final secret = await _credentials.readSecretKey();
    if (access == null || secret == null) return null;
    var deviceId = _prefs.cloudBackupDeviceId;
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = _newDeviceId();
      await _prefs.setCloudBackupDeviceId(deviceId);
    }
    final config = CloudBackupConfig(
      provider: CloudBackupProvider.fromId(_prefs.cloudBackupProvider),
      endpoint: _prefs.cloudBackupEndpoint,
      region: _prefs.cloudBackupRegion,
      bucket: _prefs.cloudBackupBucket,
      accessKey: access,
      secretKey: secret,
      forcePathStyle: _prefs.cloudBackupForcePathStyle,
      prefix: _prefs.cloudBackupPrefix,
      deviceId: deviceId,
    );
    return config.isComplete ? config : null;
  }

  Future<void> setEnabled(bool enabled) async {
    await _prefs.setCloudBackupEnabled(enabled);
    state = state.copyWith(enabled: enabled);
    if (enabled) {
      startHeartbeat();
      await checkAndMaybeRun(force: true);
    } else {
      stopHeartbeat();
    }
  }

  Future<void> saveConnection({
    required CloudBackupProvider provider,
    required String endpoint,
    required String region,
    required String bucket,
    required String prefix,
    required bool forcePathStyle,
    required String accessKey,
    required String secretKey,
  }) async {
    await _prefs.setCloudBackupProvider(provider.id);
    await _prefs.setCloudBackupEndpoint(endpoint.trim());
    await _prefs.setCloudBackupRegion(region.trim());
    await _prefs.setCloudBackupBucket(bucket.trim());
    await _prefs.setCloudBackupPrefix(prefix.trim());
    await _prefs.setCloudBackupForcePathStyle(forcePathStyle);
    await _credentials.save(accessKey: accessKey.trim(), secretKey: secretKey);
    state = state.copyWith(provider: provider, clearError: true);
  }

  Future<bool> testConnection() async {
    final config = await loadConfig();
    if (config == null) return false;
    return S3CompatibleClient(config).testConnection();
  }

  Future<void> registerEncryptionPassword(String password) async {
    await _vaultKeys.registerPassword(password);
    state = state.copyWith(needsPassword: false, clearError: true);
  }

  Future<bool> unlockEncryptionPassword(String password) async {
    final ok = await _vaultKeys.unlock(password);
    if (ok) {
      state = state.copyWith(needsPassword: false, clearError: true);
    }
    return ok;
  }

  Future<void> unlink({bool clearInventory = true}) async {
    stopHeartbeat();
    await _prefs.clearCloudBackupConfig();
    await _credentials.clear();
    await _vaultKeys.clear();
    if (clearInventory) {
      await _inventory.clear();
    }
    state = const CloudBackupState();
  }

  Future<void> checkAndMaybeRun({bool force = false}) async {
    if (!state.enabled && !force) return;
    if (_runLock) return;
    await run(force: force);
  }

  Future<void> run({bool force = false}) async {
    if (_runLock) return;
    if (!state.enabled && !force) return;
    _runLock = true;

    try {
      if (!await _onWifiOrEthernet()) {
        state = state.copyWith(phase: CloudBackupPhase.waitingForWifi);
        return;
      }

      final config = await loadConfig();
      if (config == null) {
        state = state.copyWith(phase: CloudBackupPhase.needsConfig);
        return;
      }

      if (!await _vaultKeys.isConfigured() || !await _vaultKeys.hasPassword()) {
        state = state.copyWith(
          phase: CloudBackupPhase.needsPassword,
          needsPassword: true,
        );
        return;
      }

      final key = await _vaultKeys.deriveEncryptionKey();
      if (key == null) {
        state = state.copyWith(
          phase: CloudBackupPhase.needsPassword,
          needsPassword: true,
        );
        return;
      }

      if (isGallerySyncRunning?.call() == true) {
        await waitForGallerySync?.call();
      }

      state = state.copyWith(
        phase: CloudBackupPhase.checking,
        isRunning: true,
        clearError: true,
        processed: 0,
        total: 0,
      );

      await _media.resetStaleCloudBackupInProgress();
      final client = S3CompatibleClient(config);
      final ok = await client.testConnection();
      if (!ok) {
        state = state.copyWith(
          phase: CloudBackupPhase.error,
          errorMessage: 'Could not reach cloud storage',
          isRunning: false,
        );
        return;
      }

      final pending = await _media.countMediaPendingCloudBackup();
      if (pending == 0) {
        state = state.copyWith(
          phase: CloudBackupPhase.idle,
          isRunning: false,
          lastBackupAt: _prefs.lastCloudBackupAt,
        );
        return;
      }

      state = state.copyWith(
        phase: CloudBackupPhase.syncing,
        total: pending,
        processed: 0,
      );
      await _notifications?.onBackupStarted();

      final tempRoot = await Directory.systemTemp.createTemp('sg_cloud_up_');
      var processed = 0;
      var failed = 0;

      try {
        while (true) {
          if (!await _onWifiOrEthernet()) {
            state = state.copyWith(phase: CloudBackupPhase.waitingForWifi);
            break;
          }

          final batch = await _media.getMediaPendingCloudBackup(limit: _batchSize);
          if (batch.isEmpty) break;

          final small = <MediaItem>[];
          final large = <MediaItem>[];
          for (final item in batch) {
            if (item.size >= _largeFileBytes || item.isVideo) {
              large.add(item);
            } else {
              small.add(item);
            }
          }

          Future<void> uploadOne(MediaItem item) async {
            final success = await _uploadItem(
              item: item,
              config: config,
              client: client,
              key: key,
              tempRoot: tempRoot.path,
            );
            processed++;
            if (!success) failed++;
            state = state.copyWith(
              processed: processed,
              detail: item.displayName,
            );
            await _notifications?.onBackupProgress(
              processed: processed,
              total: pending,
              detail: item.displayName,
              bytesSent: state.bytesSent,
              bytesTotal: state.bytesTotal,
            );
          }

          await runWithConcurrency(
            items: small,
            concurrency: _imageConcurrency,
            task: (item, _) => uploadOne(item),
          );
          for (final item in large) {
            await uploadOne(item);
          }
        }

        final now = DateTime.now();
        await _prefs.setLastCloudBackupAt(now);
        state = state.copyWith(
          phase: CloudBackupPhase.idle,
          isRunning: false,
          lastBackupAt: now,
          detail: failed > 0 ? '$failed failed' : '',
        );
        await _notifications?.onBackupFinished(
          success: failed == 0,
          message: failed == 0
              ? 'Uploaded $processed items'
              : 'Uploaded with $failed failures',
        );
        onBackupFinished?.call();
      } finally {
        try {
          await tempRoot.delete(recursive: true);
        } catch (_) {}
      }
    } catch (e, st) {
      debugPrint('Cloud backup failed: $e\n$st');
      state = state.copyWith(
        phase: CloudBackupPhase.error,
        errorMessage: e.toString(),
        isRunning: false,
      );
      await _notifications?.onBackupFinished(
        success: false,
        message: e.toString(),
      );
    } finally {
      _runLock = false;
      if (!state.isRunning) {
        await _notifications?.onBackupStopped();
      }
    }
  }

  Future<bool> _uploadItem({
    required MediaItem item,
    required CloudBackupConfig config,
    required S3CompatibleClient client,
    required Uint8List key,
    required String tempRoot,
  }) async {
    await _media.updateCloudBackupState(item.id, MediaBackupState.inProgress);
    try {
      final plain = await _openMediaFile(item);
      if (plain == null) {
        await _media.updateCloudBackupState(item.id, MediaBackupState.failed);
        return false;
      }

      final existing = await _inventory.lookup(item.id);
      if (existing != null) {
        final checksum = await StreamingVaultCryptor.sha256File(plain.path);
        if (existing.plaintextChecksum == checksum &&
            await client.objectExists(existing.objectKey)) {
          await _media.markMediaCloudBackedUp(
            id: item.id,
            objectKey: existing.objectKey,
          );
          return true;
        }
      }

      final encPath = p.join(tempRoot, '${item.id}.sgvault2');
      state = state.copyWith(detail: 'Encrypting ${item.displayName}');
      final encrypted = await _cryptor.encryptFile(
        plainPath: plain.path,
        outputPath: encPath,
        encryptionKey: key,
        fileName: item.displayName,
        mimeType: item.mimeType,
      );

      final objectKey = config.objectKeyForChecksum(encrypted.checksum);
      if (await client.objectExists(objectKey)) {
        await _inventory.upsert(
          mediaId: item.id,
          objectKey: objectKey,
          plaintextChecksum: encrypted.checksum,
          size: item.size,
        );
        await _media.markMediaCloudBackedUp(id: item.id, objectKey: objectKey);
        return true;
      }

      state = state.copyWith(
        detail: 'Uploading ${item.displayName}',
        bytesSent: 0,
        bytesTotal: encrypted.cipherSize,
      );

      await client.uploadFile(
        objectKey: objectKey,
        filePath: encPath,
        onProgress: (sent, total) {
          state = state.copyWith(bytesSent: sent, bytesTotal: total);
        },
      );

      await _inventory.upsert(
        mediaId: item.id,
        objectKey: objectKey,
        plaintextChecksum: encrypted.checksum,
        size: item.size,
      );
      await _media.markMediaCloudBackedUp(id: item.id, objectKey: objectKey);

      try {
        await File(encPath).delete();
      } catch (_) {}
      return true;
    } catch (e) {
      debugPrint('Cloud upload failed for ${item.id}: $e');
      await _media.updateCloudBackupState(item.id, MediaBackupState.failed);
      return false;
    }
  }

  Future<File?> _openMediaFile(MediaItem item) async {
    try {
      if (item.uri.startsWith('/') || item.uri.contains(':\\')) {
        final f = File(item.uri);
        if (await f.exists()) return f;
      }
      final entity = await AssetEntity.fromId(item.uri);
      if (entity == null) return null;
      return await entity.originFile ?? await entity.loadFile(isOrigin: true);
    } catch (e) {
      debugPrint('Open media for cloud backup failed: $e');
      return null;
    }
  }

  Future<bool> _onWifiOrEthernet() async {
    final results = await _connectivity.checkConnectivity();
    return results.any(
      (r) =>
          r == ConnectivityResult.wifi || r == ConnectivityResult.ethernet,
    );
  }

  String _newDeviceId() {
    final r = Random.secure();
    final bytes = List.generate(8, (_) => r.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Download + decrypt a cloud object for in-app preview.
  Future<File?> downloadAndDecrypt(MediaItem item) async {
    final config = await loadConfig();
    final key = await _vaultKeys.deriveEncryptionKey();
    final objectKey = item.cloudObjectKey;
    if (config == null || key == null || objectKey == null) return null;

    final dir = await getTemporaryDirectory();
    final encPath = p.join(dir.path, 'cloud_dl_${item.id}.sgvault2');
    final client = S3CompatibleClient(config);
    await client.downloadFile(objectKey: objectKey, outputPath: encPath);
    final result = await _cryptor.decryptToTempFile(
      vaultPath: encPath,
      encryptionKey: key,
    );
    try {
      await File(encPath).delete();
    } catch (_) {}
    return result.file;
  }
}
