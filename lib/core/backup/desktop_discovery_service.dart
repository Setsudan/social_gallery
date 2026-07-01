import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:social_gallery/core/backup/backup_protocol.dart';

/// Binds mDNS sockets without `reusePort` on Android (unsupported).
Future<RawDatagramSocket> mdnsDatagramSocketFactory(
  dynamic host,
  int port, {
  bool reuseAddress = true,
  bool reusePort = true,
  int ttl = 1,
}) {
  final allowReusePort =
      reusePort && !kIsWeb && !Platform.isAndroid;
  return RawDatagramSocket.bind(
    host,
    port,
    reuseAddress: reuseAddress,
    reusePort: allowReusePort,
    ttl: ttl,
  );
}

/// Discovers desktop backup servers on the local network via mDNS.
class DesktopDiscoveryService {
  Future<DiscoveredDesktop?> discover({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    if (kIsWeb) return null;

    final client = MDnsClient(
      rawDatagramSocketFactory: mdnsDatagramSocketFactory,
    );
    await client.start();

    try {
      final completer = Completer<DiscoveredDesktop?>();
      Timer? timer;

      timer = Timer(timeout, () {
        if (!completer.isCompleted) completer.complete(null);
      });

      await for (final ptr in client.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer(BackupProtocol.serviceType),
      )) {
        await for (final srv in client.lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(ptr.domainName),
        )) {
          final host = srv.target;
          final port = srv.port;
          var deviceName = host;

          await for (final txt in client.lookup<TxtResourceRecord>(
            ResourceRecordQuery.text(ptr.domainName),
          )) {
            final text = txt.text;
            if (text.startsWith('device=')) {
              deviceName = text.substring('device='.length);
            }
          }

          final resolvedHost = await _resolveHost(client, host);
          if (resolvedHost != null && !completer.isCompleted) {
            timer.cancel();
            completer.complete(
              DiscoveredDesktop(
                host: resolvedHost,
                port: port,
                deviceName: deviceName,
              ),
            );
            break;
          }
        }
        if (completer.isCompleted) break;
      }

      if (!completer.isCompleted) {
        timer.cancel();
        completer.complete(null);
      }

      return completer.future;
    } finally {
      client.stop();
    }
  }

  Future<String?> _resolveHost(MDnsClient client, String host) async {
    await for (final ip in client.lookup<IPAddressResourceRecord>(
      ResourceRecordQuery.addressIPv4(host),
    )) {
      return ip.address.address;
    }
    return null;
  }
}
