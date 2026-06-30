import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:social_gallery/core/backup/backup_file_metadata.dart';
import 'package:social_gallery/core/backup/backup_protocol.dart';
import 'package:social_gallery/core/backup/desktop_backup_inventory.dart';
import 'package:social_gallery/core/backup/pairing_service.dart';

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
  });

  final int mediaId;
  final String targetPath;
  final String expectedChecksum;
  final BackupFileMetadata metadata;
  final String folderName;
  final String fileName;
  RandomAccessFile? _file;

  Future<void> appendChunk(List<int> bytes) async {
    if (_file == null) {
      final file = File(targetPath);
      await file.parent.create(recursive: true);
      _file = await file.open(mode: FileMode.writeOnly);
    }
    await _file!.writeFrom(bytes);
  }

  Future<void> finalize() async {
    await _file?.close();
    _file = null;
  }

  Future<String> computeChecksum() => _hashFile(targetPath);
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
    DesktopBackupInventory? inventory,
  }) : _inventory = inventory ?? DesktopBackupInventory(backupRoot: backupRoot);

  final PairingService pairing;
  final String deviceName;
  final String backupRoot;
  final VoidCallback? onFileImported;
  final void Function(String mobileDeviceName)? onPaired;
  final VoidCallback? onUnpaired;
  final DesktopBackupInventory _inventory;

  DesktopBackupInventory get inventory => _inventory;

  HttpServer? _server;
  int? _port;
  final _sessions = <String, _UploadSession>{};

  int? get port => _port;

  bool get isRunning => _server != null;

  Future<void> start() async {
    if (_server != null) return;

    await _inventory.load();

    final router = Router();
    router.get('/v1/health', _handleHealth);
    router.post('/v1/pair', _handlePair);
    router.post('/v1/unpair', _handleUnpair);
    router.post('/v1/backup/init', _handleBackupInit);
    router.post('/v1/backup/reconcile', _handleReconcile);
    router.post('/v1/backup/verify', _handleVerify);
    router.put('/v1/backup/chunk/<sessionId>', _handleChunk);
    router.post('/v1/backup/complete', _handleComplete);

    final handler = Pipeline()
        .addMiddleware(_logRequests)
        .addHandler(router.call);

    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 0);
    _port = _server!.port;
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

  Future<Response> _handleHealth(Request request) async {
    final token = _authToken(request);
    final tokenValid = token != null && pairing.isValidToken(token);
    return _json({
      'status': 'ready',
      'deviceName': deviceName,
      'protocolVersion': BackupProtocol.protocolVersion,
      'tokenValid': tokenValid,
    });
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
        );
      }
      return BackupReconcileStatus.present;
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

        final status = await _resolveItemStatus(
          mediaId: mediaId,
          checksum: checksum,
          folderName: folderName,
          name: name,
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

        final reconcileStatus = await _resolveItemStatus(
          mediaId: mediaId,
          checksum: checksum,
          folderName: folderName,
          name: name,
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
        final metadata = BackupFileMetadata.fromInitJson(item);

        final status = await _resolveItemStatus(
          mediaId: mediaId,
          checksum: checksum,
          folderName: folderName,
          name: name,
        );

        if (status == BackupReconcileStatus.present) {
          final entry = _inventory.lookup(mediaId) ??
              _inventory.lookupByCanonicalPath(folderName, name);
          final targetPath = entry != null
              ? p.join(backupRoot, entry.relativePath)
              : _canonicalPath(name, folderName);
          await applyBackupFileMetadata(targetPath, metadata);
          sessions.add({
            'mediaId': mediaId,
            'sessionId': 'exists-$mediaId',
            'relativePath': p.relative(targetPath, from: backupRoot),
            'alreadyExists': true,
          });
          continue;
        }

        final targetPath = status == BackupReconcileStatus.mismatch
            ? _allocateUniquePath(name, folderName)
            : _canonicalPath(name, folderName);

        if (await File(targetPath).exists()) {
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
        );

        sessions.add({
          'mediaId': mediaId,
          'sessionId': sessionId,
          'relativePath': p.relative(targetPath, from: backupRoot),
          'alreadyExists': false,
        });
      }

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
          if (entry != null && entry.checksum == checksum) {
            onFileImported?.call();
            return _json({
              'success': true,
              'path': entry.relativePath,
              'mediaId': mediaId,
              'checksum': checksum,
            });
          }
        }
        onFileImported?.call();
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
      final actual = await session.computeChecksum();
      if (actual != checksum) {
        final file = File(session.targetPath);
        if (await file.exists()) {
          await file.delete();
        }
        return _json({'success': false, 'error': 'Checksum mismatch'}, status: 400);
      }

      await applyBackupFileMetadata(session.targetPath, session.metadata);

      final relativePath = p.relative(session.targetPath, from: backupRoot);
      await _recordInventoryEntry(
        mediaId: session.mediaId,
        checksum: checksum,
        folderName: session.folderName,
        fileName: session.fileName,
        relativePath: relativePath,
      );

      onFileImported?.call();

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

  Future<void> _recordInventoryEntry({
    required int mediaId,
    required String checksum,
    required String folderName,
    required String fileName,
    required String relativePath,
  }) async {
    await _inventory.upsert(
      BackupInventoryEntry(
        mediaId: mediaId,
        checksum: checksum,
        relativePath: relativePath.replaceAll('\\', '/'),
        folderName: DesktopBackupInventory.sanitizeFolderName(folderName),
        fileName: DesktopBackupInventory.sanitizeFileName(fileName),
        syncedAtMs: DateTime.now().millisecondsSinceEpoch,
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
