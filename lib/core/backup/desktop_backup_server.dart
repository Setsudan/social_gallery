import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:social_gallery/core/backup/backup_file_metadata.dart';
import 'package:social_gallery/core/backup/backup_protocol.dart';
import 'package:social_gallery/core/backup/desktop_backup_inventory.dart';
import 'package:social_gallery/core/backup/pairing_service.dart';
import 'package:social_gallery/core/backup/vault_archive_service.dart';
import 'package:social_gallery/core/backup/vault_config_store.dart';

Future<String> _hashFile(String path) async {
  final digest = await sha256.bind(File(path).openRead()).first;
  return digest.toString();
}

/// In-memory upload session state on the desktop receiver.
class _UploadSession {
  _UploadSession({
    required this.mediaId,
    required this.targetPath,
    required this.expectedChecksum,
    required this.metadata,
    required this.folderName,
    required this.fileName,
    required this.isVault,
    this.mime,
    this.plainSize,
  }) {
    _hashSink = sha256.startChunkedConversion(_hashAccumulator);
  }

  final int mediaId;
  final String targetPath;
  final String expectedChecksum;
  final BackupFileMetadata metadata;
  final String folderName;
  final String fileName;
  final bool isVault;
  final String? mime;
  final int? plainSize;
  final DateTime createdAt = DateTime.now();
  RandomAccessFile? _file;
  int bytesReceived = 0;
  bool _hashClosed = false;
  final _hashAccumulator = _SessionDigestAccumulator();
  late final ByteConversionSink _hashSink;

  String get displayName => '$folderName/$fileName';

  int get expectedBytes => plainSize ?? 0;

  Future<void> appendChunk(List<int> bytes) async {
    if (_file == null) {
      final file = File(targetPath);
      await file.parent.create(recursive: true);
      _file = await file.open(mode: FileMode.writeOnly);
    }
    if (!_hashClosed) {
      _hashSink.add(bytes);
    }
    await _file!.writeFrom(bytes);
    bytesReceived += bytes.length;
  }

  Future<void> finalize() async {
    await _file?.close();
    _file = null;
    if (!_hashClosed) {
      _hashSink.close();
      _hashClosed = true;
    }
  }

  Future<void> discard() async {
    await finalize();
    final file = File(targetPath);
    if (await file.exists()) {
      try {
        await file.parent.delete(recursive: true);
      } catch (_) {}
    }
  }

  String computeChecksum() {
    if (!_hashClosed) {
      _hashSink.close();
      _hashClosed = true;
    }
    return _hashAccumulator.value?.toString() ?? '';
  }
}

class _SessionDigestAccumulator implements Sink<Digest> {
  Digest? value;

  @override
  void add(Digest data) {
    value = data;
  }

  @override
  void close() {}
}

class _DownloadSession {
  _DownloadSession({
    required this.mediaId,
    required this.filePath,
    required this.size,
    required this.mime,
    required this.isVault,
    this.tempFile,
  });

  final int mediaId;
  final String filePath;
  final int size;
  final String mime;
  final bool isVault;
  final File? tempFile;
  final DateTime createdAt = DateTime.now();
}

/// HTTP backup receiver that runs on desktop when receive mode is enabled.
class DesktopBackupServer {
  DesktopBackupServer({
    required this.pairing,
    required this.deviceName,
    required this.backupRoot,
    this.onFileImported,
    this.onPaired,
    this.onUnpaired,
    this.onVaultFileStored,
    this.onReceivingStateChanged,
    DesktopBackupInventory? inventory,
    VaultConfigStore? vaultConfig,
    VaultArchiveService? vaultArchive,
  })  : _inventory = inventory ?? DesktopBackupInventory(backupRoot: backupRoot),
        _vaultConfig = vaultConfig ?? VaultConfigStore(backupRoot: backupRoot),
        _vaultArchive = vaultArchive ?? VaultArchiveService();

  final PairingService pairing;
  final String deviceName;
  final String backupRoot;
  final VoidCallback? onFileImported;
  final void Function(String mobileDeviceName)? onPaired;
  final VoidCallback? onUnpaired;
  final VoidCallback? onVaultFileStored;
  void Function(
    bool receiving,
    int completedCount, {
    String? currentFileName,
    int bytesReceived,
    int bytesTotal,
  })? onReceivingStateChanged;
  final DesktopBackupInventory _inventory;
  final VaultConfigStore _vaultConfig;
  final VaultArchiveService _vaultArchive;

  DesktopBackupInventory get inventory => _inventory;
  VaultConfigStore get vaultConfig => _vaultConfig;

  HttpServer? _server;
  int? _port;
  final _sessions = <String, _UploadSession>{};
  final _downloadSessions = <String, _DownloadSession>{};
  final _vaultTokens = <String, DateTime>{};
  Uint8List? _vaultEncryptionKey;
  bool _isReceivingBackup = false;
  int _receivingCompletedCount = 0;
  int _activeBackupOperations = 0;
  Timer? _receivingIdleTimer;
  Timer? _uploadSessionCleanupTimer;
  DateTime? _lastReceivingNotify;

  static const _vaultTokenTtl = Duration(minutes: 15);
  static const _downloadSessionTtl = Duration(minutes: 30);
  static const _uploadSessionTtl = Duration(minutes: 30);
  static const _maxDownloadSessions = 20;
  static const _receivingIdleDelay = Duration(seconds: 5);
  static const _receivingNotifyThrottle = Duration(seconds: 1);

  int? get port => _port;

  bool get isRunning => _server != null;

  bool get isReceivingBackup => _isReceivingBackup;

  int get receivingCompletedCount => _receivingCompletedCount;

  int get vaultFileCount =>
      _inventory.allEntries.where((entry) => entry.isVault).length;

  /// Removes all in-progress upload sessions. For tests only.
  @visibleForTesting
  Future<void> expireUploadSessionsForTest() async {
    final expired = _sessions.keys.toList();
    for (final sessionId in expired) {
      final session = _sessions.remove(sessionId);
      await session?.discard();
    }
    if (expired.isNotEmpty) {
      _scheduleReceivingEnd();
      _notifyReceivingState(force: true);
    }
  }

  Future<void> start() async {
    if (_server != null) return;

    await _inventory.load();
    await _vaultConfig.load();

    final router = Router();
    router.get('/v1/health', _handleHealth);
    router.post('/v1/pair', _handlePair);
    router.post('/v1/unpair', _handleUnpair);
    router.post('/v1/vault/register', _handleVaultRegister);
    router.post(
      '/v1/backup/init',
      (request) => _withBackupActivity(() => _handleBackupInit(request)),
    );
    router.post(
      '/v1/backup/reconcile',
      (request) => _withBackupActivity(() => _handleReconcile(request)),
    );
    router.post(
      '/v1/backup/verify',
      (request) => _withBackupActivity(() => _handleVerify(request)),
    );
    router.put(
      '/v1/backup/chunk/<sessionId>',
      (request, sessionId) =>
          _withBackupActivity(() => _handleChunk(request, sessionId)),
    );
    router.post(
      '/v1/backup/complete',
      (request) => _withBackupActivity(() => _handleComplete(request)),
    );
    router.get('/v1/library/catalog', _handleLibraryCatalog);
    router.get('/v1/library/thumbnail/<mediaId>', _handleLibraryThumbnail);
    router.post('/v1/library/vault/unlock', _handleVaultUnlock);
    router.post('/v1/library/stream/init', _handleStreamInit);
    router.get('/v1/library/stream/chunk/<sessionId>', _handleStreamChunk);

    final handler = Pipeline()
        .addMiddleware(_logRequests)
        .addHandler(router.call);

    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 0);
    _port = _server!.port;
    _uploadSessionCleanupTimer?.cancel();
    _uploadSessionCleanupTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => unawaited(_cleanupUploadSessions()),
    );
    debugPrint('Backup server listening on port $_port');
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _port = null;
    for (final session in _sessions.values) {
      await session.finalize();
    }
    _sessions.clear();
    await _cleanupDownloadSessions();
    _vaultTokens.clear();
    _vaultEncryptionKey = null;
    _receivingIdleTimer?.cancel();
    _receivingIdleTimer = null;
    _uploadSessionCleanupTimer?.cancel();
    _uploadSessionCleanupTimer = null;
    _activeBackupOperations = 0;
    _setReceiving(false);
  }

  _UploadSession? _primaryUploadSession() {
    if (_sessions.isEmpty) return null;
    return _sessions.values.first;
  }

  void _notifyReceivingState({bool force = false}) {
    final session = _primaryUploadSession();
    final now = DateTime.now();
    if (!force &&
        _lastReceivingNotify != null &&
        now.difference(_lastReceivingNotify!) < _receivingNotifyThrottle) {
      return;
    }
    _lastReceivingNotify = now;

    onReceivingStateChanged?.call(
      _isReceivingBackup,
      _receivingCompletedCount,
      currentFileName: session?.displayName,
      bytesReceived: session?.bytesReceived ?? 0,
      bytesTotal: session?.expectedBytes ?? 0,
    );
  }

  void _setReceiving(bool receiving) {
    if (receiving) {
      if (!_isReceivingBackup) {
        _isReceivingBackup = true;
        _notifyReceivingState(force: true);
      }
      return;
    }

    _receivingIdleTimer?.cancel();
    _receivingIdleTimer = null;
    if (!_isReceivingBackup) return;

    _isReceivingBackup = false;
    _receivingCompletedCount = 0;
    _notifyReceivingState(force: true);
  }

  void _enterBackupActivity() {
    _receivingIdleTimer?.cancel();
    _receivingIdleTimer = null;
    _setReceiving(true);
  }

  void _scheduleReceivingEnd() {
    if (_sessions.isNotEmpty || _activeBackupOperations > 0) {
      _enterBackupActivity();
      return;
    }

    _receivingIdleTimer?.cancel();
    _receivingIdleTimer = Timer(_receivingIdleDelay, () {
      if (_sessions.isEmpty && _activeBackupOperations == 0) {
        _setReceiving(false);
      }
    });
  }

  Future<T> _withBackupActivity<T>(Future<T> Function() fn) async {
    _activeBackupOperations++;
    _enterBackupActivity();
    try {
      return await fn();
    } finally {
      _activeBackupOperations--;
      _scheduleReceivingEnd();
    }
  }

  void _recordSuccessfulComplete() {
    _receivingCompletedCount++;
    _notifyReceivingState(force: true);
  }

  Middleware get _logRequests => (Handler inner) {
    return (Request request) async {
      final response = await inner(request);
      debugPrint(
        '${request.method} ${request.requestedUri.path} -> ${response.statusCode}',
      );
      return response;
    };
  };

  Response _json(Map<String, dynamic> body, {int status = 200}) {
    return Response(
      status,
      body: BackupProtocol.encodeJson(body),
      headers: {'Content-Type': 'application/json'},
    );
  }

  String? _authToken(Request request) {
    final header = request.headers['authorization'];
    if (header == null || !header.startsWith('Bearer ')) return null;
    return header.substring('Bearer '.length);
  }

  Future<Response?> _requireAuth(Request request) async {
    final token = _authToken(request);
    if (token == null || !pairing.isValidToken(token)) {
      return _json({'error': 'Unauthorized'}, status: 401);
    }
    return null;
  }

  bool _isValidVaultToken(String? token) {
    if (token == null || token.isEmpty) return false;
    final expiresAt = _vaultTokens[token];
    if (expiresAt == null) return false;
    if (DateTime.now().isAfter(expiresAt)) {
      _vaultTokens.remove(token);
      return false;
    }
    return true;
  }

  String _createVaultToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final token = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    _vaultTokens[token] = DateTime.now().add(_vaultTokenTtl);
    return token;
  }

  Future<void> _cleanupDownloadSessions() async {
    final now = DateTime.now();
    final expired = <String>[];
    for (final entry in _downloadSessions.entries) {
      if (now.difference(entry.value.createdAt) > _downloadSessionTtl) {
        expired.add(entry.key);
      }
    }
    for (final sessionId in expired) {
      final session = _downloadSessions.remove(sessionId);
      if (session?.tempFile != null && await session!.tempFile!.exists()) {
        try {
          await session.tempFile!.parent.delete(recursive: true);
        } catch (_) {}
      }
    }
  }

  Future<void> _cleanupUploadSessions() async {
    if (_sessions.isEmpty) return;

    final now = DateTime.now();
    final expired = <String>[];
    for (final entry in _sessions.entries) {
      if (now.difference(entry.value.createdAt) > _uploadSessionTtl) {
        expired.add(entry.key);
      }
    }

    for (final sessionId in expired) {
      final session = _sessions.remove(sessionId);
      await session?.discard();
    }

    if (expired.isNotEmpty) {
      _scheduleReceivingEnd();
      _notifyReceivingState(force: true);
    }
  }

  Future<Response> _handleHealth(Request request) async {
    final token = _authToken(request);
    final tokenValid = token != null && pairing.isValidToken(token);
    return _json({
      'status': 'ready',
      'deviceName': deviceName,
      'protocolVersion': BackupProtocol.protocolVersion,
      'tokenValid': tokenValid,
      'capabilities': const ['backup', 'library', 'vault'],
      'vaultConfigured': _vaultConfig.isConfigured,
    });
  }

  Future<Response> _handleVaultRegister(Request request) async {
    final authError = await _requireAuth(request);
    if (authError != null) return authError;

    try {
      final body = BackupProtocol.decodeJson(await request.readAsString());
      final password = body['password'] as String? ?? '';
      if (password.length < 8) {
        return _json({'error': 'Password must be at least 8 characters'}, status: 400);
      }

      await _vaultConfig.registerPassword(password);
      _vaultEncryptionKey = _vaultConfig.deriveEncryptionKey(password);

      return _json({'success': true});
    } catch (e) {
      return _json({'error': e.toString()}, status: 400);
    }
  }

  Future<Response> _handleVaultUnlock(Request request) async {
    final authError = await _requireAuth(request);
    if (authError != null) return authError;

    try {
      final body = BackupProtocol.decodeJson(await request.readAsString());
      final password = body['password'] as String? ?? '';
      if (!_vaultConfig.validatePassword(password)) {
        return _json({'error': 'Invalid vault password'}, status: 401);
      }

      _vaultEncryptionKey = _vaultConfig.deriveEncryptionKey(password);
      final token = _createVaultToken();
      return _json({
        'vaultToken': token,
        'expiresAtMs': _vaultTokens[token]!.millisecondsSinceEpoch,
      });
    } catch (e) {
      return _json({'error': e.toString()}, status: 400);
    }
  }

  Future<Response> _handlePair(Request request) async {
    try {
      final body = BackupProtocol.decodeJson(await request.readAsString());
      final pin = body['pin'] as String? ?? '';
      final mobileName = body['deviceName'] as String? ?? 'Mobile';

      if (!pairing.validatePin(pin)) {
        return _json({'error': 'Invalid or expired PIN'}, status: 401);
      }

      final token = pairing.createToken();
      final desktopId = deviceName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

      pairing.clearPin();
      await pairing.saveDesktopReceiverToken(
        token: token,
        desktopId: desktopId,
        mobileDeviceName: mobileName,
      );

      onPaired?.call(mobileName);

      return _json({
        'token': token,
        'deviceId': desktopId,
        'desktopName': deviceName,
        'mobileDeviceName': mobileName,
      });
    } catch (e) {
      return _json({'error': e.toString()}, status: 400);
    }
  }

  Future<Response> _handleUnpair(Request request) async {
    final authError = await _requireAuth(request);
    if (authError != null) return authError;

    await pairing.clearDesktopReceiverPairing();
    onUnpaired?.call();
    return _json({'success': true});
  }

  Future<BackupReconcileStatus> _resolveItemStatus({
    required int mediaId,
    required String checksum,
    required String folderName,
    required String name,
    bool isVault = false,
    bool linkMediaId = true,
  }) async {
    final byId = _inventory.lookup(mediaId);
    if (byId != null) {
      if (byId.checksum == checksum) {
        return BackupReconcileStatus.present;
      }
      return BackupReconcileStatus.mismatch;
    }

    final canonical = _inventory.lookupByCanonicalPath(folderName, name);
    if (canonical != null) {
      if (canonical.checksum == checksum) {
        if (linkMediaId) {
          await _recordInventoryEntry(
            mediaId: mediaId,
            checksum: checksum,
            folderName: folderName,
            fileName: name,
            relativePath: canonical.relativePath,
            storageKind: canonical.storageKind,
            size: canonical.size,
            mime: canonical.mime,
            dateTaken: canonical.dateTaken,
          );
        }
        return BackupReconcileStatus.present;
      }
      return BackupReconcileStatus.mismatch;
    }

    final byChecksum =
        _inventory.lookupByChecksumInFolder(folderName, checksum);
    if (byChecksum != null) {
      if (linkMediaId) {
        await _recordInventoryEntry(
          mediaId: mediaId,
          checksum: checksum,
          folderName: folderName,
          fileName: name,
          relativePath: byChecksum.relativePath,
          storageKind: byChecksum.storageKind,
          size: byChecksum.size,
          mime: byChecksum.mime,
          dateTaken: byChecksum.dateTaken,
        );
      }
      return BackupReconcileStatus.present;
    }

    if (isVault) {
      return BackupReconcileStatus.missing;
    }

    final canonicalPath = _canonicalPath(name, folderName);
    if (await File(canonicalPath).exists()) {
      final existingHash = await _hashFile(canonicalPath);
      if (existingHash == checksum) {
        if (linkMediaId) {
          await _recordInventoryEntry(
            mediaId: mediaId,
            checksum: checksum,
            folderName: folderName,
            fileName: name,
            relativePath: p.relative(canonicalPath, from: backupRoot),
          );
        }
        return BackupReconcileStatus.present;
      }
      return BackupReconcileStatus.mismatch;
    }

    return BackupReconcileStatus.missing;
  }

  Future<Response> _handleReconcile(Request request) async {
    final authError = await _requireAuth(request);
    if (authError != null) return authError;

    try {
      final body = BackupProtocol.decodeJson(await request.readAsString());
      final items = (body['items'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final results = <Map<String, dynamic>>[];

      for (final item in items) {
        final mediaId = item['id'] as int;
        final checksum = item['checksum'] as String;
        final folderName = item['folderName'] as String? ?? 'Backup';
        final name = item['name'] as String;
        final isVault = item['isVault'] as bool? ?? false;

        final status = await _resolveItemStatus(
          mediaId: mediaId,
          checksum: checksum,
          folderName: folderName,
          name: name,
          isVault: isVault,
        );

        results.add({
          'mediaId': mediaId,
          'status': status.name,
        });
      }

      return _json({'results': results});
    } catch (e) {
      return _json({'error': e.toString()}, status: 400);
    }
  }

  Future<Response> _handleVerify(Request request) async {
    final authError = await _requireAuth(request);
    if (authError != null) return authError;

    try {
      final body = BackupProtocol.decodeJson(await request.readAsString());
      final items = (body['items'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final results = <Map<String, dynamic>>[];

      for (final item in items) {
        final mediaId = item['id'] as int;
        final checksum = item['checksum'] as String;
        final folderName = item['folderName'] as String? ?? 'Backup';
        final name = item['name'] as String;
        final isVault = item['isVault'] as bool? ?? false;

        final reconcileStatus = await _resolveItemStatus(
          mediaId: mediaId,
          checksum: checksum,
          folderName: folderName,
          name: name,
          isVault: isVault,
          linkMediaId: false,
        );

        final status = reconcileStatus == BackupReconcileStatus.present
            ? BackupVerifyStatus.present
            : BackupVerifyStatus.missing;

        results.add({
          'mediaId': mediaId,
          'status': status.name,
        });
      }

      return _json({'results': results});
    } catch (e) {
      return _json({'error': e.toString()}, status: 400);
    }
  }

  Future<Response> _handleBackupInit(Request request) async {
    final authError = await _requireAuth(request);
    if (authError != null) return authError;

    try {
      final body = BackupProtocol.decodeJson(await request.readAsString());
      final items = (body['items'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final sessions = <Map<String, dynamic>>[];

      for (final item in items) {
        final mediaId = item['id'] as int;
        final name = item['name'] as String;
        final folderName = item['folderName'] as String? ?? 'Backup';
        final checksum = item['checksum'] as String;
        final isVault = item['isVault'] as bool? ?? false;
        final metadata = BackupFileMetadata.fromInitJson(item);

        if (isVault && !_vaultConfig.isConfigured) {
          return _json({'error': 'Vault not configured on desktop'}, status: 400);
        }

        final status = await _resolveItemStatus(
          mediaId: mediaId,
          checksum: checksum,
          folderName: folderName,
          name: name,
          isVault: isVault,
        );

        if (status == BackupReconcileStatus.present) {
          final entry = _inventory.lookup(mediaId) ??
              _inventory.lookupByCanonicalPath(folderName, name);
          if (entry != null && !entry.isVault) {
            final targetPath = p.join(backupRoot, entry.relativePath);
            await applyBackupFileMetadata(targetPath, metadata);
          }
          sessions.add({
            'mediaId': mediaId,
            'sessionId': 'exists-$mediaId',
            'relativePath': entry?.relativePath ?? '',
            'alreadyExists': true,
          });
          continue;
        }

        final targetPath = isVault
            ? p.join(
                backupRoot,
                '.social_gallery',
                'upload-temp',
                '$mediaId-${DateTime.now().millisecondsSinceEpoch}',
                DesktopBackupInventory.sanitizeFileName(name),
              )
            : status == BackupReconcileStatus.mismatch
                ? _allocateUniquePath(name, folderName)
                : _canonicalPath(name, folderName);

        if (!isVault && await File(targetPath).exists()) {
          await File(targetPath).delete();
        }

        final sessionId = '$mediaId-${DateTime.now().millisecondsSinceEpoch}';
        _sessions[sessionId] = _UploadSession(
          mediaId: mediaId,
          targetPath: targetPath,
          expectedChecksum: checksum,
          metadata: metadata,
          folderName: folderName,
          fileName: name,
          isVault: isVault,
          mime: item['mime'] as String?,
          plainSize: item['size'] as int?,
        );

        sessions.add({
          'mediaId': mediaId,
          'sessionId': sessionId,
          'relativePath': isVault
              ? VaultArchiveService.vaultRelativePath(folderName, name)
              : p.relative(targetPath, from: backupRoot),
          'alreadyExists': false,
        });
      }

      _notifyReceivingState(force: true);
      return _json({'sessions': sessions});
    } catch (e) {
      return _json({'error': e.toString()}, status: 400);
    }
  }

  Future<Response> _handleChunk(Request request, String sessionId) async {
    final token = _authToken(request);
    if (token == null || !pairing.isValidToken(token)) {
      return Response.forbidden('Unauthorized');
    }

    if (sessionId.startsWith('exists-')) {
      return Response.ok('skipped');
    }

    final session = _sessions[sessionId];
    if (session == null) {
      return Response.notFound('Unknown session');
    }

    try {
      final stream = request.read();
      await for (final bytes in stream) {
        await session.appendChunk(bytes);
      }
      _notifyReceivingState(force: true);
      return Response.ok('ok');
    } catch (e) {
      debugPrint('Chunk write failed: $e');
      return Response.internalServerError(body: e.toString());
    }
  }

  Future<Response> _handleComplete(Request request) async {
    final authError = await _requireAuth(request);
    if (authError != null) return authError;

    try {
      final body = BackupProtocol.decodeJson(await request.readAsString());
      final sessionId = body['sessionId'] as String;
      final checksum = body['checksum'] as String;

      if (sessionId.startsWith('exists-')) {
        final mediaId = int.tryParse(sessionId.substring('exists-'.length));
        if (mediaId != null) {
          final entry = _inventory.lookup(mediaId);
          if (entry != null && entry.checksum == checksum && !entry.isVault) {
            onFileImported?.call();
            _recordSuccessfulComplete();
            return _json({
              'success': true,
              'path': entry.relativePath,
              'mediaId': mediaId,
              'checksum': checksum,
            });
          }
        }
        _recordSuccessfulComplete();
        return _json({
          'success': true,
          'path': '',
          'mediaId': mediaId,
          'checksum': checksum,
        });
      }

      final session = _sessions.remove(sessionId);
      if (session == null) {
        return _json({'success': false, 'error': 'Unknown session'}, status: 404);
      }

      await session.finalize();
      final actual = session.computeChecksum();
      if (actual != checksum) {
        final file = File(session.targetPath);
        if (await file.exists()) {
          await file.delete();
        }
        return _json({'success': false, 'error': 'Checksum mismatch'}, status: 400);
      }

      if (session.isVault) {
        if (_vaultEncryptionKey == null) {
          return _json({'success': false, 'error': 'Vault key unavailable'}, status: 400);
        }

        final vaultRelative =
            VaultArchiveService.vaultRelativePath(session.folderName, session.fileName);
        final vaultPath = p.join(backupRoot, vaultRelative);

        await _vaultArchive.encryptToVaultArchive(
          plainPath: session.targetPath,
          outputPath: vaultPath,
          encryptionKey: _vaultEncryptionKey!,
          innerFileName: session.fileName,
        );

        await File(session.targetPath).delete();
        try {
          await Directory(p.dirname(session.targetPath)).delete(recursive: true);
        } catch (_) {}

        await _recordInventoryEntry(
          mediaId: session.mediaId,
          checksum: checksum,
          folderName: session.folderName,
          fileName: session.fileName,
          relativePath: vaultRelative.replaceAll('\\', '/'),
          storageKind: BackupStorageKind.vault,
          size: session.plainSize,
          mime: session.mime,
          dateTaken: session.metadata.dateTaken,
        );

        onVaultFileStored?.call();

        _recordSuccessfulComplete();
        return _json({
          'success': true,
          'path': vaultRelative,
          'mediaId': session.mediaId,
          'checksum': checksum,
        });
      }

      await applyBackupFileMetadata(session.targetPath, session.metadata);

      final relativePath = p.relative(session.targetPath, from: backupRoot);
      await _recordInventoryEntry(
        mediaId: session.mediaId,
        checksum: checksum,
        folderName: session.folderName,
        fileName: session.fileName,
        relativePath: relativePath,
        size: session.plainSize,
        mime: session.mime,
        dateTaken: session.metadata.dateTaken,
      );

      onFileImported?.call();

      _recordSuccessfulComplete();
      return _json({
        'success': true,
        'path': relativePath,
        'mediaId': session.mediaId,
        'checksum': checksum,
      });
    } catch (e) {
      return _json({'success': false, 'error': e.toString()}, status: 400);
    }
  }

  Future<Response> _handleLibraryCatalog(Request request) async {
    final authError = await _requireAuth(request);
    if (authError != null) return authError;

    try {
      final params = request.requestedUri.queryParameters;
      final folderFilter = params['folderName'];
      final limit = int.tryParse(params['limit'] ?? '50') ?? 50;
      final cursor = int.tryParse(params['cursor'] ?? '0') ?? 0;

      final entries = _inventory.allEntries
          .where((entry) => entry.mediaId != null)
          .where(
            (entry) =>
                folderFilter == null ||
                folderFilter.isEmpty ||
                entry.folderName == folderFilter,
          )
          .toList()
        ..sort((a, b) => (b.syncedAtMs ?? 0).compareTo(a.syncedAtMs ?? 0));

      final page = entries.skip(cursor).take(limit).toList();
      final nextCursor =
          cursor + page.length < entries.length ? '${cursor + page.length}' : null;

      final folderCounts = <String, ({int count, bool isVault})>{};
      for (final entry in entries) {
        final current = folderCounts[entry.folderName];
        final vault = entry.isVault || (current?.isVault ?? false);
        folderCounts[entry.folderName] = (
          count: (current?.count ?? 0) + 1,
          isVault: vault,
        );
      }

      return _json({
        'folders': folderCounts.entries
            .map(
              (entry) => {
                'folderName': entry.key,
                'itemCount': entry.value.count,
                'isVault': entry.value.isVault,
              },
            )
            .toList(),
        'items': page
            .map(
              (entry) => {
                'mediaId': entry.mediaId,
                'folderName': entry.folderName,
                'fileName': entry.fileName,
                'mime': entry.mime ?? _guessMime(entry.fileName),
                'size': entry.size ?? 0,
                'isVault': entry.isVault,
                if (entry.dateTaken != null) 'dateTaken': entry.dateTaken,
                if (entry.syncedAtMs != null) 'syncedAtMs': entry.syncedAtMs,
              },
            )
            .toList(),
        'totalCount': entries.length,
        'nextCursor': ?nextCursor,
      });
    } catch (e) {
      return _json({'error': e.toString()}, status: 400);
    }
  }

  Future<Response> _handleLibraryThumbnail(Request request, String mediaIdStr) async {
    final authError = await _requireAuth(request);
    if (authError != null) return authError;

    final mediaId = int.tryParse(mediaIdStr);
    if (mediaId == null) {
      return Response.badRequest(body: 'Invalid mediaId');
    }

    final entry = _inventory.lookup(mediaId);
    if (entry == null) {
      return Response.notFound('Not found');
    }

    if (entry.isVault && !_isValidVaultToken(request.url.queryParameters['vaultToken'])) {
      return Response.forbidden('Vault token required');
    }

    try {
      final thumbPath = p.join(
        backupRoot,
        '.social_gallery',
        'thumbs',
        '$mediaId.jpg',
      );
      final thumbFile = File(thumbPath);
      if (await thumbFile.exists()) {
        return Response.ok(
          await thumbFile.readAsBytes(),
          headers: {'Content-Type': 'image/jpeg'},
        );
      }

      final sourcePath = await _resolveReadablePath(entry);
      if (sourcePath == null) {
        return Response.notFound('File missing');
      }

      final bytes = await File(sourcePath).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        return Response.notFound('Unsupported image');
      }

      final thumb = img.copyResize(decoded, width: 320);
      final jpeg = Uint8List.fromList(img.encodeJpg(thumb, quality: 80));
      await thumbFile.parent.create(recursive: true);
      await thumbFile.writeAsBytes(jpeg);

      if (entry.isVault && sourcePath.contains('sg_vault_')) {
        try {
          await Directory(p.dirname(sourcePath)).delete(recursive: true);
        } catch (_) {}
      }

      return Response.ok(jpeg, headers: {'Content-Type': 'image/jpeg'});
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  }

  Future<Response> _handleStreamInit(Request request) async {
    final authError = await _requireAuth(request);
    if (authError != null) return authError;

    try {
      await _cleanupDownloadSessions();
      if (_downloadSessions.length >= _maxDownloadSessions) {
        return _json({'error': 'Too many active stream sessions'}, status: 429);
      }

      final body = BackupProtocol.decodeJson(await request.readAsString());
      final mediaId = body['mediaId'] as int;
      final vaultToken = body['vaultToken'] as String?;

      final entry = _inventory.lookup(mediaId);
      if (entry == null) {
        return _json({'error': 'Not found'}, status: 404);
      }

      if (entry.isVault && !_isValidVaultToken(vaultToken)) {
        return _json({'error': 'Valid vault token required'}, status: 401);
      }

      File? tempFile;
      String readablePath;
      var size = entry.size ?? 0;

      if (entry.isVault) {
        if (_vaultEncryptionKey == null) {
          return _json({'error': 'Vault key unavailable'}, status: 401);
        }
        tempFile = await _vaultArchive.decryptToTempFile(
          vaultPath: p.join(backupRoot, entry.relativePath),
          encryptionKey: _vaultEncryptionKey!,
        );
        readablePath = tempFile.path;
        size = await tempFile.length();
      } else {
        readablePath = p.join(backupRoot, entry.relativePath);
        if (!await File(readablePath).exists()) {
          return _json({'error': 'File missing on disk'}, status: 404);
        }
        size = await File(readablePath).length();
      }

      final sessionId = 'dl-$mediaId-${DateTime.now().millisecondsSinceEpoch}';
      _downloadSessions[sessionId] = _DownloadSession(
        mediaId: mediaId,
        filePath: readablePath,
        size: size,
        mime: entry.mime ?? _guessMime(entry.fileName),
        isVault: entry.isVault,
        tempFile: tempFile,
      );

      return _json({
        'sessionId': sessionId,
        'size': size,
        'mime': entry.mime ?? _guessMime(entry.fileName),
        'supportsRange': true,
      });
    } catch (e) {
      return _json({'error': e.toString()}, status: 400);
    }
  }

  Future<Response> _handleStreamChunk(Request request, String sessionId) async {
    final token = _authToken(request);
    if (token == null || !pairing.isValidToken(token)) {
      return Response.forbidden('Unauthorized');
    }

    final session = _downloadSessions[sessionId];
    if (session == null) {
      return Response.notFound('Unknown session');
    }

    try {
      final rangeHeader = request.headers['range'];
      var start = 0;
      var end = session.size - 1;

      if (rangeHeader != null && rangeHeader.startsWith('bytes=')) {
        final parts = rangeHeader.substring(6).split('-');
        start = int.tryParse(parts[0]) ?? 0;
        if (parts.length > 1 && parts[1].isNotEmpty) {
          end = int.tryParse(parts[1]) ?? end;
        }
      }

      if (start < 0) start = 0;
      if (end >= session.size) end = session.size - 1;
      if (start > end) {
        return Response(416);
      }

      final length = end - start + 1;
      final file = await File(session.filePath).open();
      await file.setPosition(start);
      final bytes = await file.read(length);
      await file.close();

      final headers = {
        'Content-Type': session.mime,
        'Accept-Ranges': 'bytes',
        'Content-Length': '$length',
      };

      if (rangeHeader != null) {
        headers['Content-Range'] = 'bytes $start-$end/${session.size}';
        return Response(206, body: bytes, headers: headers);
      }

      return Response.ok(bytes, headers: headers);
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  }

  Future<String?> _resolveReadablePath(BackupInventoryEntry entry) async {
    if (!entry.isVault) {
      final path = p.join(backupRoot, entry.relativePath);
      return await File(path).exists() ? path : null;
    }

    if (_vaultEncryptionKey == null) return null;
    final temp = await _vaultArchive.decryptToTempFile(
      vaultPath: p.join(backupRoot, entry.relativePath),
      encryptionKey: _vaultEncryptionKey!,
    );
    return temp.path;
  }

  String _guessMime(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.heic':
      case '.heif':
        return 'image/heic';
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      case '.webm':
        return 'video/webm';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _recordInventoryEntry({
    required int mediaId,
    required String checksum,
    required String folderName,
    required String fileName,
    required String relativePath,
    BackupStorageKind storageKind = BackupStorageKind.plain,
    int? size,
    String? mime,
    int? dateTaken,
  }) async {
    await _inventory.upsert(
      BackupInventoryEntry(
        mediaId: mediaId,
        checksum: checksum,
        relativePath: relativePath.replaceAll('\\', '/'),
        folderName: DesktopBackupInventory.sanitizeFolderName(folderName),
        fileName: DesktopBackupInventory.sanitizeFileName(fileName),
        syncedAtMs: DateTime.now().millisecondsSinceEpoch,
        storageKind: storageKind,
        size: size,
        mime: mime,
        dateTaken: dateTaken,
      ),
    );
  }

  String _canonicalPath(String fileName, String folderName) {
    final safeName = DesktopBackupInventory.sanitizeFileName(fileName);
    final folder = DesktopBackupInventory.sanitizeFolderName(folderName);
    final dir = Directory(p.join(backupRoot, folder));
    dir.createSync(recursive: true);
    return p.join(dir.path, safeName);
  }

  String _allocateUniquePath(String fileName, String folderName) {
    final safeName = DesktopBackupInventory.sanitizeFileName(fileName);
    final folder = DesktopBackupInventory.sanitizeFolderName(folderName);
    final dir = Directory(p.join(backupRoot, folder));
    dir.createSync(recursive: true);

    var target = p.join(dir.path, safeName);
    if (!File(target).existsSync()) return target;

    final ext = p.extension(safeName);
    final base = p.basenameWithoutExtension(safeName);
    var counter = 1;
    while (File(target).existsSync()) {
      target = p.join(dir.path, '$base ($counter)$ext');
      counter++;
    }
    return target;
  }
}

/// Returns the first non-loopback IPv4 address for pairing display.
Future<String?> getLocalIpAddress() async {
  final interfaces = await NetworkInterface.list(
    type: InternetAddressType.IPv4,
    includeLinkLocal: false,
  );
  for (final iface in interfaces) {
    for (final addr in iface.addresses) {
      if (!addr.isLoopback) return addr.address;
    }
  }
  return null;
}
