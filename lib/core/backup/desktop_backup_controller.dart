import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/core/backup/backup_concurrency.dart';
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
import 'package:social_gallery/domain/models/media_item.dart';

/// Per-file upload phase shown in progress UI.
enum BackupSyncPhase {
  idle,
  preparing,
  uploading,
  completing,
}

class _BatchUploadProgress {
  const _BatchUploadProgress({
    required this.bytesSent,
    required this.bytesTotal,
    required this.phase,
    required this.fileDetail,
  });

  final int bytesSent;
  final int bytesTotal;
  final BackupSyncPhase phase;
  final String fileDetail;
}

class _BatchUploadTracker {
  final Map<int, _BatchUploadProgress> _items = {};

  void update({
    required int mediaId,
    required int bytesSent,
    required int bytesTotal,
    required BackupSyncPhase phase,
    required String fileDetail,
  }) {
    _items[mediaId] = _BatchUploadProgress(
      bytesSent: bytesSent,
      bytesTotal: bytesTotal,
      phase: phase,
      fileDetail: fileDetail,
    );
  }

  void remove(int mediaId) => _items.remove(mediaId);

  int get activeCount => _items.length;

  int get aggregateBytesSent =>
      _items.values.fold(0, (sum, item) => sum + item.bytesSent);

  int get aggregateBytesTotal =>
      _items.values.fold(0, (sum, item) => sum + item.bytesTotal);

  BackupSyncPhase get aggregatePhase {
    if (_items.values.any((item) => item.phase == BackupSyncPhase.uploading)) {
      return BackupSyncPhase.uploading;
    }
    if (_items.values.any((item) => item.phase == BackupSyncPhase.completing)) {
      return BackupSyncPhase.completing;
    }
    return BackupSyncPhase.preparing;
  }

  String buildDetail() {
    if (_items.isEmpty) return '';
    if (_items.length == 1) {
      final progress = _items.values.first;
      if (progress.bytesTotal > 0) {
        final percent =
            ((progress.bytesSent / progress.bytesTotal) * 100).round();
        return '${progress.fileDetail} ($percent%)';
      }
      return progress.fileDetail;
    }

    final total = aggregateBytesTotal;
    final percent =
        total > 0 ? ((aggregateBytesSent / total) * 100).round() : 0;
    return 'Backing up ${_items.length} files ($percent%)';
  }
}

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
    this.isReceivingBackup = false,
    this.receivingCompletedCount = 0,
    this.syncingPhase = BackupSyncPhase.idle,
    this.syncingBytesSent = 0,
    this.syncingBytesTotal = 0,
    this.syncingStartedAt,
    this.receivingFileName,
    this.receivingBytesReceived = 0,
    this.receivingBytesTotal = 0,
    this.failedThisRun = 0,
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
  final bool isReceivingBackup;
  final int receivingCompletedCount;
  final BackupSyncPhase syncingPhase;
  final int syncingBytesSent;
  final int syncingBytesTotal;
  final DateTime? syncingStartedAt;
  final String? receivingFileName;
  final int receivingBytesReceived;
  final int receivingBytesTotal;
  final int failedThisRun;

  double? get progress => total > 0 ? processed / total : null;

  double? get fileProgress =>
      syncingBytesTotal > 0 ? syncingBytesSent / syncingBytesTotal : null;

  double? get receivingFileProgress =>
      receivingBytesTotal > 0
          ? receivingBytesReceived / receivingBytesTotal
          : null;

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
    bool? isReceivingBackup,
    int? receivingCompletedCount,
    BackupSyncPhase? syncingPhase,
    int? syncingBytesSent,
    int? syncingBytesTotal,
    DateTime? syncingStartedAt,
    String? receivingFileName,
    int? receivingBytesReceived,
    int? receivingBytesTotal,
    int? failedThisRun,
    bool clearSyncingMediaId = false,
    bool clearSyncingProgress = false,
    bool clearReceivingProgress = false,
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
      isReceivingBackup: isReceivingBackup ?? this.isReceivingBackup,
      receivingCompletedCount:
          receivingCompletedCount ?? this.receivingCompletedCount,
      syncingPhase: clearSyncingProgress
          ? BackupSyncPhase.idle
          : (syncingPhase ?? this.syncingPhase),
      syncingBytesSent: clearSyncingProgress
          ? 0
          : (syncingBytesSent ?? this.syncingBytesSent),
      syncingBytesTotal: clearSyncingProgress
          ? 0
          : (syncingBytesTotal ?? this.syncingBytesTotal),
      syncingStartedAt: clearSyncingProgress
          ? null
          : (syncingStartedAt ?? this.syncingStartedAt),
      receivingFileName: clearReceivingProgress
          ? null
          : (receivingFileName ?? this.receivingFileName),
      receivingBytesReceived: clearReceivingProgress
          ? 0
          : (receivingBytesReceived ?? this.receivingBytesReceived),
      receivingBytesTotal: clearReceivingProgress
          ? 0
          : (receivingBytesTotal ?? this.receivingBytesTotal),
      failedThisRun: failedThisRun ?? this.failedThisRun,
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
  static const _backupConcurrency = 4;
  static const _reconcileChunkSize = 100;
  static const _verifySampleSize = 50;
  bool _backfillInProgress = false;
  final BackupSessionChecksumCache _checksumCache = BackupSessionChecksumCache();

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
    if (!enabled && state.isReceivingBackup) return;
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
      onReceivingStateChanged: _onReceivingStateChanged,
    );
    _server!.onReceivingStateChanged = _onReceivingStateChanged;

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

  void _onReceivingStateChanged(
    bool receiving,
    int completedCount, {
    String? currentFileName,
    int bytesReceived = 0,
    int bytesTotal = 0,
  }) {
    if (!usesFilesystemGallery) return;

    final deviceName = _prefs.pairedMobileDeviceName ?? 'phone';
    String detail;
    if (receiving && currentFileName != null && currentFileName.isNotEmpty) {
      if (bytesTotal > 0) {
        final percent = ((bytesReceived / bytesTotal) * 100).round();
        detail = '$currentFileName - $percent%';
      } else {
        detail = currentFileName;
      }
    } else if (receiving) {
      detail = 'Receiving backup from $deviceName';
    } else {
      detail = _pairing.isDesktopReceiverPaired
          ? 'Paired with ${_prefs.pairedMobileDeviceName}'
          : 'Ready to receive backups';
    }

    state = state.copyWith(
      isReceivingBackup: receiving,
      receivingCompletedCount: completedCount,
      receivingFileName: currentFileName,
      receivingBytesReceived: bytesReceived,
      receivingBytesTotal: bytesTotal,
      clearReceivingProgress: !receiving,
      detail: detail,
      phase: receiving
          ? DesktopBackupPhase.syncing
          : DesktopBackupPhase.desktopReady,
    );
  }

  Future<void> _stopDesktopServer() async {
    if (state.isReceivingBackup) return;
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
    _checksumCache.clear();
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
      var failedThisRun = 0;
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

          if (totalProcessed == 0 && failedThisRun == 0) {
            state = state.copyWith(
              isRunning: false,
              phase: DesktopBackupPhase.done,
              detail: 'All photos are backed up',
              clearSyncingProgress: true,
            );
          } else {
            await _prefs.setLastBackupAt(DateTime.now());
            final detail = failedThisRun > 0
                ? 'Backed up $totalProcessed items, $failedThisRun failed'
                : 'Backed up $totalProcessed items';
            state = state.copyWith(
              isRunning: false,
              phase: DesktopBackupPhase.done,
              detail: detail,
              processed: totalProcessed,
              total: totalProcessed + failedThisRun,
              failedThisRun: failedThisRun,
              clearSyncingProgress: true,
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

        final uploadClient = client;

        var abortBatch = false;
        var disconnectDuringBatch = false;
        final uploadTracker = _BatchUploadTracker();
        var lastProgressNotifyAt = DateTime.now();

        void refreshUploadState({
          bool forceNotify = false,
          bool phaseChanged = false,
        }) {
          final detail = uploadTracker.buildDetail();
          if (detail.isNotEmpty) {
            state = state.copyWith(
              detail: detail,
              processed: totalProcessed,
              syncingPhase: uploadTracker.aggregatePhase,
              syncingBytesSent: uploadTracker.aggregateBytesSent,
              syncingBytesTotal: uploadTracker.aggregateBytesTotal,
              syncingStartedAt: state.syncingStartedAt ?? DateTime.now(),
              failedThisRun: failedThisRun,
              clearSyncingMediaId: true,
            );
          }

          final now = DateTime.now();
          final shouldNotify = forceNotify ||
              phaseChanged ||
              now.difference(lastProgressNotifyAt) >=
                  const Duration(seconds: 1);
          if (shouldNotify) {
            lastProgressNotifyAt = now;
            unawaited(_syncBackupNotification(force: forceNotify || phaseChanged));
          }
        }

        final preparedUploads = await runWithConcurrency(
          items: pending,
          concurrency: _backupConcurrency,
          shouldCancel: () => abortBatch,
          task: (item, _) async {
            if (abortBatch) return null;

            final file = await uploadClient.openMediaFile(item);
            if (file == null) return null;

            var checksum = _checksumCache.lookup(item);
            if (checksum == null) {
              checksum = await uploadClient.computeFileChecksum(file);
              if (checksum == null) return null;
              _checksumCache.put(item, checksum);
            }

            return (item: item, file: file, checksum: checksum);
          },
        );

        final readyUploads = preparedUploads.whereType<
            ({MediaItem item, File file, String checksum})>().toList();

        if (readyUploads.isEmpty) {
          for (final item in pending) {
            await _mediaRepo.updateBackupState(item.id, MediaBackupState.failed);
            failedThisRun++;
          }
          state = state.copyWith(
            processed: totalProcessed,
            failedThisRun: failedThisRun,
            clearSyncingProgress: true,
          );
          await _syncBackupNotification();
          continue;
        }

        final initItems = readyUploads
            .map(
              (upload) => BackupInitItem(
                id: upload.item.id,
                name: upload.item.displayName,
                folderName: upload.item.folderName,
                size: upload.item.size,
                mime: upload.item.mimeType,
                checksum: upload.checksum,
                dateTaken: upload.item.dateTaken,
                dateModified: upload.item.dateModified,
                dateAdded: upload.item.dateAdded,
                latitude: upload.item.latitude,
                longitude: upload.item.longitude,
                isVault: upload.item.isVault,
              ),
            )
            .toList();

        final initResponse = await uploadClient.initBackup(initItems);
        if (initResponse == null) {
          for (final upload in readyUploads) {
            await _mediaRepo.updateBackupState(
              upload.item.id,
              MediaBackupState.failed,
            );
            failedThisRun++;
          }
          if (!await _isStillAvailable(availability)) {
            abortBatch = true;
            disconnectDuringBatch = true;
          }
        } else {
          final sessionsByMediaId = {
            for (final session in initResponse.sessions)
              session.mediaId: BackupUploadSession(
                sessionId: session.sessionId,
                alreadyExists: session.alreadyExists,
              ),
          };

          final uploadResults = await runWithConcurrency(
            items: readyUploads,
            concurrency: _backupConcurrency,
            shouldCancel: () => abortBatch,
            task: (upload, _) async {
              if (abortBatch) return false;

              final session = sessionsByMediaId[upload.item.id];
              if (session == null) return false;

              await _mediaRepo.updateBackupState(
                upload.item.id,
                MediaBackupState.inProgress,
              );

              final fileDetail =
                  'Backing up ${upload.item.folderName}/${upload.item.displayName}';
              uploadTracker.update(
                mediaId: upload.item.id,
                bytesSent: 0,
                bytesTotal: upload.item.size,
                phase: BackupSyncPhase.preparing,
                fileDetail: fileDetail,
              );
              refreshUploadState(forceNotify: true, phaseChanged: true);

              var lastPhase = BackupSyncPhase.preparing;
              final success = await uploadClient.uploadPreparedFile(
                upload.item,
                upload.file,
                checksum: upload.checksum,
                uploadSession: session,
                onProgress: ({
                  required BackupUploadPhase phase,
                  required int bytesSent,
                  required int bytesTotal,
                }) {
                  final syncPhase = switch (phase) {
                    BackupUploadPhase.preparing => BackupSyncPhase.preparing,
                    BackupUploadPhase.uploading => BackupSyncPhase.uploading,
                    BackupUploadPhase.completing => BackupSyncPhase.completing,
                  };
                  final phaseChanged = syncPhase != lastPhase;
                  lastPhase = syncPhase;
                  uploadTracker.update(
                    mediaId: upload.item.id,
                    bytesSent: bytesSent,
                    bytesTotal: bytesTotal,
                    phase: syncPhase,
                    fileDetail: fileDetail,
                  );
                  refreshUploadState(phaseChanged: phaseChanged);
                },
                onStall: (fileName) {
                  unawaited(_notifications?.onBackupStallWarning(fileName));
                },
              );

              uploadTracker.remove(upload.item.id);
              uploadClient.clearOpenFileCache();

              if (success) {
                await _mediaRepo.markMediaBackedUp(upload.item.id);
                return true;
              }

              await _mediaRepo.updateBackupState(
                upload.item.id,
                MediaBackupState.failed,
              );
              if (!await _isStillAvailable(availability)) {
                abortBatch = true;
                disconnectDuringBatch = true;
              }
              return false;
            },
          );

          for (final success in uploadResults) {
            if (success == null) continue;
            if (success) {
              totalProcessed++;
            } else {
              failedThisRun++;
            }
          }

          final failedPrepareCount = pending.length - readyUploads.length;
          failedThisRun += failedPrepareCount;
        }

        uploadClient.clearOpenFileCache();

        if (disconnectDuringBatch) {
          state = state.copyWith(
            phase: DesktopBackupPhase.waitingForDesktop,
            detail: 'Desktop disconnected during backup',
            isRunning: false,
            processed: totalProcessed,
            failedThisRun: failedThisRun,
            clearSyncingMediaId: true,
            clearSyncingProgress: true,
          );
          _scheduleRetry();
          client.close();
          return;
        }

        state = state.copyWith(
          processed: totalProcessed,
          failedThisRun: failedThisRun,
          clearSyncingProgress: true,
        );
        await _syncBackupNotification();
      }

      client.close();
      state = state.copyWith(
        clearSyncingMediaId: true,
        clearSyncingProgress: true,
      );
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
      _checksumCache.clear();
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

      final skipReconcile = <MediaItem>[];
      final needsReconcile = <MediaItem>[];
      for (final item in pending) {
        if (item.backupState == MediaBackupState.pending &&
            item.lastSyncTime == null) {
          skipReconcile.add(item);
        } else {
          needsReconcile.add(item);
        }
      }

      reconciledIds.addAll(skipReconcile.map((item) => item.id));

      if (needsReconcile.isEmpty) {
        continue;
      }

      final items = <BackupReconcileItem>[];

      final checksumResults = await runWithConcurrency(
        items: needsReconcile,
        concurrency: _backupConcurrency,
        task: (item, _) async {
          final checksum = await client.computeChecksum(item);
          return (item: item, checksum: checksum);
        },
      );

      for (final result in checksumResults) {
        if (result == null) continue;
        final checksum = result.checksum;
        if (checksum == null) continue;
        _checksumCache.put(result.item, checksum);
        items.add(
          BackupReconcileItem.fromMedia(
            id: result.item.id,
            checksum: checksum,
            folderName: result.item.folderName,
            name: result.item.displayName,
            isVault: result.item.isVault,
          ),
        );
      }

      if (items.isEmpty) {
        reconciledIds.addAll(needsReconcile.map((item) => item.id));
        client.clearOpenFileCache();
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
      reconciledIds.addAll(needsReconcile.map((item) => item.id));
      client.clearOpenFileCache();

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
    final checksumResults = await runWithConcurrency(
      items: sample,
      concurrency: _backupConcurrency,
      task: (item, _) async {
        final checksum = await client.computeChecksum(item);
        return (item: item, checksum: checksum);
      },
    );

    for (final result in checksumResults) {
      if (result == null) continue;
      final checksum = result.checksum;
      if (checksum == null) continue;
      items.add(
        BackupReconcileItem.fromMedia(
          id: result.item.id,
          checksum: checksum,
          folderName: result.item.folderName,
          name: result.item.displayName,
          isVault: result.item.isVault,
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
      bytesSent: state.syncingBytesSent,
      bytesTotal: state.syncingBytesTotal,
      phase: state.syncingPhase.name,
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
