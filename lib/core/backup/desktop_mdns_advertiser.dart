import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/foundation.dart';
import 'package:social_gallery/core/backup/backup_protocol.dart';

/// Advertises the desktop backup server on the local network via mDNS/Bonjour.
class DesktopMdnsAdvertiser {
  BonsoirBroadcast? _broadcast;

  bool get isAdvertising => _broadcast != null;

  Future<void> start({
    required String deviceName,
    required int port,
  }) async {
    await stop();

    final service = BonsoirService(
      name: deviceName,
      type: BackupProtocol.serviceType,
      port: port,
      attributes: {'device': deviceName},
    );

    _broadcast = BonsoirBroadcast(service: service);
    await _broadcast!.ready;
    await _broadcast!.start();
    debugPrint('mDNS advertising $deviceName on port $port');
  }

  Future<void> stop() async {
    if (_broadcast == null) return;
    try {
      await _broadcast!.stop();
    } catch (e) {
      debugPrint('mDNS stop failed: $e');
    }
    _broadcast = null;
  }
}
