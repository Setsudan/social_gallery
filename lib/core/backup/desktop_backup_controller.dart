import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/core/backup/backup_protocol.dart';
import 'package:social_gallery/core/backup/desktop_availability_service.dart';
import 'package:social_gallery/core/backup/desktop_backup_client.dart';
import 'package:social_gallery/core/backup/desktop_backup_inventory.dart';
import 'package:social_gallery/core/backup/desktop_discovery_service.dart';
import 'package:social_gallery/core/backup/desktop_backup_server.dart';
import 'package:social_gallery/core/backup/pairing_service.dart';
import 'package:social_gallery/core/backup/desktop_mdns_advertiser.dart';
import 'package:social_gallery/core/backup/vault_password_store.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';
import 'package:social_gallery/core/notifications/desktop_backup_notification_service.dart';
import 'package:social_gallery/data/repositories/media_repository.dart';
import 'package:social_gallery/data/repositories/preferences_repository.dart';
import 'package:social_gallery/domain/models/backup_state.dart';

/// Phase of the desktop backup state machine.
enum DesktopBackupPhase {
  disabled,
  idle,
  discovering,
  waitingForDesktop,
  desktopReady,
  indexing,
  reconciling,
  verifying,
  syncing,
  done,
  error,
}

/// Observable backup progress for settings and status UI.
class DesktopBackupState {
  const DesktopBackupState({
    this.phase = DesktopBackupPhase.idle,
    this.detail = '',
    this.processed = 0,
    this.total = 0,
    this.error,
    this.isRunning = false,
    this.pairedDesktopName,
    this.localServerPort,
    this.pairingPin,
    this.localIp,
    this.syncingMediaId,
    this.pairingSuccessDeviceName,
    this.needsVaultPassword = false,
    this.vaultEncryptedCount = 0,
  });

  final DesktopBackupPhase phase;
  final String detail;
  final int processed;
  final int total;
  final String? error;
  final bool isRunning;
  final String? pairedDesktopName;
  final int? localServerPort;
  final String? pairingPin;
  final String? localIp;
  final int? syncingMediaId;
  final String? pairingSuccessDeviceName;
  final bool needsVaultPassword;
  final int vaultEncryptedCount;

  double? get progress => total > 0 ? processed / total : null;

  bool get showsProgressUi =>
      isRunning &&
      (phase == DesktopBackupPhase.discovering ||
          phase == DesktopBackupPhase.indexing ||
          phase == DesktopBackupPhase.reconciling ||
          phase == DesktopBackupPhase.verifying ||
          phase == DesktopBackupPhase.syncing);

  DesktopBackupState copyWith({
    DesktopBackupPhase? phase,
    String? detail,
    int? processed,
    int? total,
    String? error,
    bool? isRunning,
    String? pairedDesktopName,
    int? localServerPort,
    String? pairingPin,
    String? localIp,
    int? syncingMediaId,
    String? pairingSuccessDeviceName,
    bool? needsVaultPassword,
    int? vaultEncryptedCount,
    bool clearSyncingMediaId = false,
    bool clearPairingPin = false,
    bool clearPairingSuccess = false,
    bool clearError = false,
  }) {
    return DesktopBackupState(
      phase: phase ?? this.phase,
      detail: detail ?? this.detail,
      processed: processed ?? this.processed,
      total: total ?? this.total,
      error: clearError ? null : (error ?? this.error),
      isRunning: isRunning ?? this.isRunning,
      pairedDesktopName: pairedDesktopName ?? this.pairedDesktopName,
      localServerPort: localServerPort ?? this.localServerPort,
      pairingPin: clearPairingPin ? null : (pairingPin ?? this.pairingPin),
      localIp: localIp ?? this.localIp,
      syncingMediaId: clearSyncingMediaId
          ? null
          : (syncingMediaId ?? this.syncingMediaId),
      pairingSuccessDeviceName: clearPairingSuccess
          ? null
          : (pairingSuccessDeviceName ?? this.pairingSuccessDeviceName),
      needsVaultPassword: needsVaultPassword ?? this.needsVaultPassword,
      vaultEncryptedCount: vaultEncryptedCount ?? this.vaultEncryptedCount,
    );
  }
}

/// Orchestrates LAN backup with availability gating and exponential backoff.
class DesktopBackupController extends StateNotifier<DesktopBackupState> {
  DesktopBackupController(
    this._prefs,
    this._mediaRepo,
    this._availability,
    this._pairing,
    this._discovery,
    this._vaultPasswordStore, {
    Future<void> Function()? onLibraryRefresh,
    VoidCallback? onBackupFinished,
    DesktopBackupNotificationService? notifications,
    bool Function()? isGallerySyncRunning,
    Future<void> Function()? waitForGallerySync,
  })  : _onLibraryRefresh = onLibraryRefresh,
        _onBackupFinished = onBackupFinished,
        _notifications = notifications,
        _isGallerySyncRunning = isGallerySyncRunning,
        _waitForGallerySync = waitForGallerySync,
        super(const DesktopBackupState()) {
    _recoverStaleInProgress();
    if (usesFilesystemGallery) {
      if (_prefs.desktopReceiveBackups) {
        unawaited(_syncDesktopServerState());
      }
    } else if (_prefs.backupEnabled) {
      state = state.copyWith(phase: DesktopBackupPhase.idle);
    } else {
      state = state.copyWith(phase: DesktopBackupPhase.disabled);
    }
  }

  final PreferencesRepository _prefs;
  final MediaRepository _mediaRepo;
  final DesktopAvailabilityService _availability;
  final PairingService _pairing;
  final DesktopDiscoveryService _discovery;
  final VaultPasswordStore _vaultPasswordStore;
  final Future<void> Function()? _onLibraryRefresh;
  final VoidCallback? _onBackupFinished;
  final DesktopBackupNotificationService? _notifications;
  final bool Function()? _isGallerySyncRunning;
  final Future<void> Function()? _waitForGallerySync;

  DesktopBackupServer? _server;
  final DesktopMdnsAdvertiser _mdnsAdvertiser = DesktopMdnsAdvertiser();
  Timer? _retryTimer;
  Timer? _heartbeatTimer;
  Timer? _libraryRefreshTimer;
  bool _runInProgress = false;
  int _backoffSeconds = 30;
  static const _maxBackoffSeconds = 300;
  static const _batchSize = 25;
  static const _reconcileChunkSize = 100;
  static const _verifySampleSize = 50;
  bool _backfillInProgress = false;

  Future<bool> registerVaultPassword(String password) async {
    await _vaultPasswordStore.savePassword(password);

    final availability = await _availability.check(discoverIfNeeded: false);
    if (!availability.available ||
        availability.host == null ||
        availability.port == null ||
        _prefs.backupAuthToken == null) {
      return false;
    }

    final client = DesktopBackupClient(
      host: availability.host!,
      port: availability.port!,
      authToken: _prefs.backupAuthToken!,
    );
    final ok = await client.registerVaultPassword(password);
    client.close();

    if (ok) {
      state = state.copyWith(needsVaultPassword: false, clearError: true);
      unawaited(checkAndMaybeRun(force: true));
    }
    return ok;
  }

  Future<bool> _ensureVaultRegistered(DesktopBackupClient client) async {
    if (!await _mediaRepo.hasPendingVaultBackup()) {
      state = state.copyWith(needsVaultPassword: false);
      return true;
    }

    var password = await _vaultPasswordStore.readPassword();
    if (password == null || password.isEmpty) {
      state = state.copyWith(
        needsVaultPassword: true,
        phase: DesktopBackupPhase.waitingForDesktop,
        detail: 'Vault password required',
        isRunning: false,
      );
      return false;
    }

    final registered = await client.registerVaultPassword(password);
    if (!registered) {
      state = state.copyWith(
        needsVaultPassword: true,
        phase: DesktopBackupPhase.error,
        detail: 'Failed to register vault password',
        isRunning: false,
      );
      return false;
    }

    state = state.copyWith(needsVaultPassword: false);
    return true;
  }

  Future<void> _recoverStaleInProgress() async {
    await _mediaRepo.resetStaleBackupInProgress();
  }

  Future<void> setBackupEnabled(bool enabled) async {
    await _prefs.setBackupEnabled(enabled);
    if (!enabled) {
      _cancelRetry();
      state = state.copyWith(
        phase: DesktopBackupPhase.disabled,
        detail: 'Backup disabled',
        isRunning: false,
      );
      return;
    }
    state = state.copyWith(phase: DesktopBackupPhase.idle, detail: '');
    if (!usesFilesystemGallery) {
      unawaited(checkAndMaybeRun());
    }
  }

  Future<void> setDesktopReceiveEnabled(bool enabled) async {
    await _prefs.setDesktopReceiveBackups(enabled);
    if (enabled) {
      await _syncDesktopServerState();
    } else {
      await _stopDesktopServer();
      state = state.copyWith(
        pairingPin: null,
        localServerPort: null,
        localIp: null,
        detail: 'Not receiving backups',
      );
    }
  }

  Future<void> _syncDesktopServerState() async {
    if (!usesFilesystemGallery || !_prefs.desktopReceiveBackups) {
      await _stopDesktopServer();
      return;
    }

    final root = _resolveBackupRoot();
    final dir = Directory(root);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final pin = _pairing.isDesktopReceiverPaired ? null : _pairing.generatePin();
    final deviceName = Platform.localHostname;

    _server ??= DesktopBackupServer(
      pairing: _pairing,
      deviceName: deviceName,
      backupRoot: root,
      onFileImported: _scheduleLibraryRefresh,
      onVaultFileStored: _refreshVaultCount,
      onPaired: _onServerPaired,
      onUnpaired: _onServerUnpaired,
    );

    if (!_server!.isRunning) {
      await _server!.start();
      await _prefs.setBackupDesktopPort(_server!.port!);
    }

    final ip = await getLocalIpAddress();
    if (_server!.port != null) {
      await _prefs.setBackupDesktopHost(ip ?? '127.0.0.1');
      await _mdnsAdvertiser.start(deviceName: deviceName, port: _server!.port!);
    }

    state = state.copyWith(
      pairingPin: pin,
      localServerPort: _server!.port,
      localIp: ip,
      vaultEncryptedCount: _server!.vaultFileCount,
      detail: _pairing.isDesktopReceiverPaired
          ? 'Paired with ${_prefs.pairedMobileDeviceName}'
          : 'Ready to receive backups',
      phase: DesktopBackupPhase.desktopReady,
    );

    unawaited(_maybeRunInventoryBackfill(root));
  }

  Future<void> _maybeRunInventoryBackfill(String root) async {
    if (_backfillInProgress) return;

    final rootChanged = _prefs.backupInventoryBackfillRoot != root;
    if (_prefs.backupInventoryBackfillDone && !rootChanged) return;

    _backfillInProgress = true;
    state = state.copyWith(
      phase: DesktopBackupPhase.indexing,
      detail: 'Indexing existing backups...',
      isRunning: true,
    );

    try {
      final inventory = _server?.inventory ??
          DesktopBackupInventory(backupRoot: root);
      await inventory.load();
      await inventory.backfillFromDisk(
        onProgress: (scanned) {
          if (scanned % 50 == 0) {
            state = state.copyWith(
              detail: 'Indexing existing backups ($scanned files)...',
            );
          }
        },
      );
      await _prefs.setBackupInventoryBackfillDone(true);
      await _prefs.setBackupInventoryBackfillRoot(root);
    } catch (e, stack) {
      debugPrint('Inventory backfill failed: $e\n$stack');
    } finally {
      _backfillInProgress = false;
      state = state.copyWith(
        isRunning: false,
        phase: DesktopBackupPhase.desktopReady,
        vaultEncryptedCount: _server?.vaultFileCount ?? 0,
        detail: _pairing.isDesktopReceiverPaired
            ? 'Paired with ${_prefs.pairedMobileDeviceName}'
            : 'Ready to receive backups',
      );
    }
  }

  void _onServerPaired(String mobileDeviceName) {
    state = state.copyWith(
      clearPairingPin: true,
      pairingSuccessDeviceName: mobileDeviceName,
      detail: 'Paired with $mobileDeviceName',
      phase: DesktopBackupPhase.desktopReady,
    );
  }

  Future<void> _onServerUnpaired() async {
    final pin = _pairing.generatePin();
    state = state.copyWith(
      pairingPin: pin,
      clearPairingSuccess: true,
      detail: 'Ready to receive backups',
      phase: DesktopBackupPhase.desktopReady,
    );
  }

  void clearPairingSuccess() {
    state = state.copyWith(clearPairingSuccess: true);
  }

  Future<void> unpairDesktopReceiver() async {
    await _pairing.clearDesktopReceiverPairing();
    await _onServerUnpaired();
  }

  String _resolveBackupRoot() {
    final custom = _prefs.desktopBackupRoot;
    if (custom != null && custom.isNotEmpty) return custom;
    final galleryRoot = _prefs.desktopGalleryRootPath;
    if (galleryRoot != null && galleryRoot.isNotEmpty) {
      return galleryRoot;
    }
    return Directory.current.path;
  }

  void _scheduleLibraryRefresh() {
    if (_onLibraryRefresh == null) return;
    _libraryRefreshTimer?.cancel();
    _libraryRefreshTimer = Timer(const Duration(seconds: 2), () {
      unawaited(_onLibraryRefresh());
    });
  }

  void _refreshVaultCount() {
    state = state.copyWith(vaultEncryptedCount: _server?.vaultFileCount ?? 0);
  }

  Future<void> _stopDesktopServer() async {
    await _mdnsAdvertiser.stop();
    await _server?.stop();
    _pairing.clearPin();
  }

  Future<void> refreshDesktopPairingPin() async {
    if (!usesFilesystemGallery || !_prefs.desktopReceiveBackups) return;
    if (_pairing.isDesktopReceiverPaired) return;
    final pin = _pairing.generatePin();
    state = state.copyWith(pairingPin: pin);
  }

  Future<bool> pairWithDesktop({
    required String host,
    required int port,
    required String pin,
    required String mobileDeviceName,
  }) async {
    final client = DesktopBackupClient(
      host: host,
      port: port,
      authToken: '',
    );

    final response = await client.pair(
      pin: pin,
      deviceName: mobileDeviceName,
    );

    if (response == null) return false;

    await _pairing.savePairing(
      token: response.token,
      desktopId: response.deviceId,
      desktopName: response.desktopName,
      host: host,
      port: port,
      mobileDeviceName: mobileDeviceName,
    );

    state = state.copyWith(
      pairedDesktopName: response.desktopName,
      phase: DesktopBackupPhase.idle,
      detail: 'Paired with ${response.desktopName}',
    );

    return true;
  }

  Future<DiscoveredDesktop?> discoverDesktop() async {
    state = state.copyWith(
      phase: DesktopBackupPhase.discovering,
      detail: 'Searching for desktop...',
      isRunning: true,
    );

    final found = await _discovery.discover();
    state = state.copyWith(
      isRunning: false,
      phase: found != null
          ? DesktopBackupPhase.idle
          : DesktopBackupPhase.waitingForDesktop,
      detail: found != null
          ? 'Found ${found.deviceName}'
          : 'No desktop found on network',
    );
    return found;
  }

  Future<void> unpair() async {
    final host = _prefs.backupDesktopHost;
    final port = _prefs.backupDesktopPort;
    final token = _prefs.backupAuthToken;

    if (host != null && port != null && token != null) {
      final client = DesktopBackupClient(
        host: host,
        port: port,
        authToken: token,
      );
      try {
        await client.unpair();
      } catch (e, stack) {
        debugPrint('Remote unpair failed: $e\n$stack');
      } finally {
        client.close();
      }
    }

    await _pairing.clearPairing();
    state = state.copyWith(
      pairedDesktopName: null,
      phase: DesktopBackupPhase.disabled,
      detail: 'Not paired',
    );
  }

  void _scheduleRetry() {
    _cancelRetry();
    _retryTimer = Timer(Duration(seconds: _backoffSeconds), () {
      unawaited(checkAndMaybeRun());
    });
    _backoffSeconds = (_backoffSeconds * 2).clamp(30, _maxBackoffSeconds);
  }

  void _cancelRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  void _resetBackoff() {
    _backoffSeconds = 30;
    _cancelRetry();
  }

  void startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (state.phase == DesktopBackupPhase.waitingForDesktop &&
          _prefs.backupEnabled &&
          !usesFilesystemGallery) {
        unawaited(checkAndMaybeRun());
      }
    });
  }

  void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> checkAndMaybeRun({bool force = false}) async {
    if (usesFilesystemGallery) return;
    if (!_prefs.backupEnabled) return;
    if (_runInProgress && !force) return;
    if (!force && (_isGallerySyncRunning?.call() ?? false)) {
      debugPrint('Backup deferred until gallery sync finishes');
      return;
    }

    state = state.copyWith(
      phase: DesktopBackupPhase.discovering,
      detail: 'Checking desktop availability...',
      isRunning: true,
    );

    final availability = await _availability.check();
    if (!availability.available) {
      state = state.copyWith(
        phase: DesktopBackupPhase.waitingForDesktop,
        detail: availability.reason ?? 'Waiting for desktop',
        isRunning: false,
      );
      _scheduleRetry();
      return;
    }

    _resetBackoff();
    state = state.copyWith(
      phase: DesktopBackupPhase.desktopReady,
      pairedDesktopName: availability.deviceName,
      detail: 'Desktop ready',
      isRunning: true,
    );

    await run(force: force);
  }

  Future<void> run({bool force = false}) async {
    if (usesFilesystemGallery) return;
    if (!_prefs.backupEnabled) return;
    if (_runInProgress && !force) return;

    final availability = await _availability.check(discoverIfNeeded: false);
    if (!availability.available) {
      state = state.copyWith(
        phase: DesktopBackupPhase.waitingForDesktop,
        detail: availability.reason ?? 'Desktop unavailable',
        isRunning: false,
      );
      _scheduleRetry();
      return;
    }

    _runInProgress = true;
    await _mediaRepo.resetStaleBackupInProgress();

    var sessionPendingTotal = await _mediaRepo.countMediaPendingBackup();
    state = state.copyWith(
      isRunning: true,
      phase: DesktopBackupPhase.reconciling,
      detail: sessionPendingTotal > 0
          ? 'Reconciling $sessionPendingTotal items'
          : 'Reconciling with desktop',
      processed: 0,
      total: sessionPendingTotal,
      clearError: true,
    );

    var notificationsActive = false;
    DesktopBackupClient? client;
    try {
      await _notifications?.onBackupStarted();
      notificationsActive = _notifications != null;
      await _syncBackupNotification(force: true);

      client = DesktopBackupClient(
        host: availability.host!,
        port: availability.port!,
        authToken: _prefs.backupAuthToken!,
      );

      if (!await _ensureVaultRegistered(client)) {
        client.close();
        return;
      }

      final reconciled = await _reconcilePending(client, availability);
      if (!reconciled) {
        client.close();
        return;
      }

      sessionPendingTotal = await _mediaRepo.countMediaPendingBackup();
      state = state.copyWith(
        total: sessionPendingTotal,
        processed: 0,
      );

      final verified = await _verifyBackedUpSample(client, availability);
      if (!verified) {
        client.close();
        return;
      }

      sessionPendingTotal = await _mediaRepo.countMediaPendingBackup();
      var totalProcessed = 0;
      var batchNumber = 0;

      state = state.copyWith(
        phase: DesktopBackupPhase.syncing,
        total: sessionPendingTotal,
        detail: sessionPendingTotal > 0
            ? 'Backing up $sessionPendingTotal items'
            : 'Checking for items to back up',
      );
      await _syncBackupNotification(force: true);

      while (true) {
        if (!await _isStillAvailable(availability)) {
          state = state.copyWith(
            phase: DesktopBackupPhase.waitingForDesktop,
            detail: 'Desktop became unavailable',
            isRunning: false,
          );
          _scheduleRetry();
          break;
        }

        final pending =
            await _mediaRepo.getMediaPendingBackup(limit: _batchSize);
        if (pending.isEmpty) {
          if (_isGallerySyncRunning?.call() ?? false) {
            state = state.copyWith(
              detail: 'Waiting for library sync to finish...',
            );
            await _syncBackupNotification(force: true);
            await _waitForGallerySync?.call();
            continue;
          }

          final remaining = await _mediaRepo.countMediaPendingBackup();
          if (remaining > 0) {
            state = state.copyWith(
              total: remaining,
              detail: 'Found $remaining more items to back up',
            );
            await _syncBackupNotification(force: true);
            continue;
          }

          if (totalProcessed == 0) {
            state = state.copyWith(
              isRunning: false,
              phase: DesktopBackupPhase.done,
              detail: 'All photos are backed up',
            );
          } else {
            await _prefs.setLastBackupAt(DateTime.now());
            state = state.copyWith(
              isRunning: false,
              phase: DesktopBackupPhase.done,
              detail: 'Backed up $totalProcessed items',
              processed: totalProcessed,
              total: totalProcessed,
            );
          }
          break;
        }

        batchNumber++;
        final remainingAfterBatch =
            await _mediaRepo.countMediaPendingBackup();
        state = state.copyWith(
          total: totalProcessed + remainingAfterBatch,
          detail: 'Backing up batch $batchNumber (${pending.length} items)',
        );
        await _syncBackupNotification();

        for (final item in pending) {
          await _mediaRepo.updateBackupState(
            item.id,
            MediaBackupState.inProgress,
          );

          state = state.copyWith(
            detail: 'Backing up ${item.folderName}/${item.displayName}',
            processed: totalProcessed,
            syncingMediaId: item.id,
          );
          await _syncBackupNotification();

          final success = await client.uploadMediaItem(item);
          if (success) {
            await _mediaRepo.markMediaBackedUp(item.id);
            totalProcessed++;
          } else {
            await _mediaRepo.updateBackupState(item.id, MediaBackupState.failed);
            final stillAvailable = await _isStillAvailable(availability);
            if (!stillAvailable) {
              state = state.copyWith(
                phase: DesktopBackupPhase.waitingForDesktop,
                detail: 'Desktop disconnected during backup',
                isRunning: false,
                processed: totalProcessed,
                clearSyncingMediaId: true,
              );
              _scheduleRetry();
              client.close();
              return;
            }
          }

          state = state.copyWith(processed: totalProcessed);
          await _syncBackupNotification();
        }
      }

      client.close();
      state = state.copyWith(clearSyncingMediaId: true);
      _onBackupFinished?.call();
    } catch (e, stack) {
      debugPrint('Backup error: $e\n$stack');
      state = state.copyWith(
        isRunning: false,
        phase: DesktopBackupPhase.error,
        error: e.toString(),
        detail: 'Backup failed',
        clearSyncingMediaId: true,
      );
      _scheduleRetry();
    } finally {
      client?.close();
      if (notificationsActive) {
        await _notifications?.onBackupStopped(
          completionTitle: _backupCompletionTitle(),
          completionBody: _backupCompletionBody(),
          isError: state.phase == DesktopBackupPhase.error,
        );
      }
      _runInProgress = false;
    }
  }

  Future<bool> _reconcilePending(
    DesktopBackupClient client,
    DesktopAvailabilityResult availability,
  ) async {
    final reconciledIds = <int>{};
    var reconciledCount = 0;

    while (true) {
      if (!await _isStillAvailable(availability)) {
        state = state.copyWith(
          phase: DesktopBackupPhase.waitingForDesktop,
          detail: 'Desktop became unavailable during reconcile',
          isRunning: false,
        );
        _scheduleRetry();
        return false;
      }

      final pending = (await _mediaRepo.getMediaPendingBackup(
        limit: _reconcileChunkSize,
      )).where((item) => !reconciledIds.contains(item.id)).toList();
      if (pending.isEmpty) break;

      final items = <BackupReconcileItem>[];
      final checksums = <int, String>{};

      for (final item in pending) {
        final checksum = await client.computeChecksum(item);
        if (checksum == null) continue;
        checksums[item.id] = checksum;
        items.add(
          BackupReconcileItem.fromMedia(
            id: item.id,
            checksum: checksum,
            folderName: item.folderName,
            name: item.displayName,
            isVault: item.isVault,
          ),
        );
      }

      if (items.isEmpty) {
        reconciledIds.addAll(pending.map((item) => item.id));
        continue;
      }

      state = state.copyWith(
        phase: DesktopBackupPhase.reconciling,
        detail: 'Reconciling ${items.length} items...',
      );
      await _syncBackupNotification();

      final response = await client.reconcileItems(items);
      if (response == null) {
        state = state.copyWith(
          phase: DesktopBackupPhase.error,
          detail: 'Reconcile failed',
          isRunning: false,
        );
        _scheduleRetry();
        return false;
      }

      final presentIds = <int>[];
      final mismatchIds = <int>[];
      final missingIds = <int>[];

      for (final result in response.results) {
        switch (result.status) {
          case BackupReconcileStatus.present:
            presentIds.add(result.mediaId);
          case BackupReconcileStatus.mismatch:
            mismatchIds.add(result.mediaId);
          case BackupReconcileStatus.missing:
            missingIds.add(result.mediaId);
        }
      }

      await _mediaRepo.reconcileBackupStates(
        presentIds: presentIds,
        mismatchIds: mismatchIds,
        missingIds: missingIds,
      );

      reconciledCount += items.length;
      reconciledIds.addAll(pending.map((item) => item.id));

      state = state.copyWith(
        processed: reconciledCount,
        total: await _mediaRepo.countMediaPendingBackup() + presentIds.length,
      );
      await _syncBackupNotification();
    }

    return true;
  }

  Future<bool> _verifyBackedUpSample(
    DesktopBackupClient client,
    DesktopAvailabilityResult availability,
  ) async {
    final backedUpCount = await _mediaRepo.countBackedUpMedia();
    if (backedUpCount == 0) return true;

    var cursor = _prefs.backupVerifyCursor;
    if (cursor >= backedUpCount) {
      cursor = 0;
    }

    final sample = await _mediaRepo.getBackedUpMediaSample(
      offset: cursor,
      limit: _verifySampleSize,
    );
    if (sample.isEmpty) return true;

    state = state.copyWith(
      phase: DesktopBackupPhase.verifying,
      detail: 'Verifying ${sample.length} backed-up items...',
    );
    await _syncBackupNotification(force: true);

    if (!await _isStillAvailable(availability)) {
      state = state.copyWith(
        phase: DesktopBackupPhase.waitingForDesktop,
        detail: 'Desktop became unavailable during verify',
        isRunning: false,
      );
      _scheduleRetry();
      return false;
    }

    final items = <BackupReconcileItem>[];
    for (final item in sample) {
      final checksum = await client.computeChecksum(item);
      if (checksum == null) continue;
      items.add(
        BackupReconcileItem.fromMedia(
          id: item.id,
          checksum: checksum,
          folderName: item.folderName,
          name: item.displayName,
          isVault: item.isVault,
        ),
      );
    }

    if (items.isEmpty) {
      await _prefs.setBackupVerifyCursor(cursor + sample.length);
      return true;
    }

    final response = await client.verifyItems(items);
    if (response == null) {
      state = state.copyWith(
        phase: DesktopBackupPhase.error,
        detail: 'Verify failed',
        isRunning: false,
      );
      _scheduleRetry();
      return false;
    }

    final missingIds = response.results
        .where((r) => r.status == BackupVerifyStatus.missing)
        .map((r) => r.mediaId)
        .toList();

    if (missingIds.isNotEmpty) {
      await _mediaRepo.markVerifiedMissingAsPending(missingIds);
    }

    await _prefs.setBackupVerifyCursor(cursor + sample.length);
    return true;
  }

  Future<void> _syncBackupNotification({bool force = false}) async {
    await _notifications?.onBackupProgress(
      processed: state.processed,
      total: state.total,
      detail: state.detail,
      force: force,
    );
  }

  String? _backupCompletionTitle() {
    if (state.phase != DesktopBackupPhase.done) {
      return switch (state.phase) {
        DesktopBackupPhase.error => 'Backup failed',
        DesktopBackupPhase.waitingForDesktop => 'Backup paused',
        _ => null,
      };
    }

    return state.processed > 0 ? 'Backup complete' : null;
  }

  String? _backupCompletionBody() {
    return switch (state.phase) {
      DesktopBackupPhase.done => state.processed > 0 ? state.detail : null,
      DesktopBackupPhase.error => state.detail,
      DesktopBackupPhase.waitingForDesktop => state.detail,
      _ => null,
    };
  }

  Future<bool> _isStillAvailable(DesktopAvailabilityResult cached) async {
    final check = await _availability.check(discoverIfNeeded: false);
    return check.available &&
        check.host == cached.host &&
        check.port == cached.port;
  }

  @override
  void dispose() {
    _cancelRetry();
    stopHeartbeat();
    _libraryRefreshTimer?.cancel();
    unawaited(_stopDesktopServer());
    super.dispose();
  }
}
