import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:social_gallery/core/backup/backup_protocol.dart';
import 'package:social_gallery/core/backup/desktop_discovery_service.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';
import 'package:social_gallery/data/repositories/preferences_repository.dart';

/// Result of pre-flight checks before starting a backup transfer.
class DesktopAvailabilityResult {
  const DesktopAvailabilityResult({
    required this.available,
    this.host,
    this.port,
    this.deviceName,
    this.reason,
  });

  final bool available;
  final String? host;
  final int? port;
  final String? deviceName;
  final String? reason;
}

/// Wi-Fi gate, discovery, and health check before any upload attempt.
class DesktopAvailabilityService {
  DesktopAvailabilityService(
    this._prefs,
    this._discovery, {
    Connectivity? connectivity,
  }) : _connectivity = connectivity ?? Connectivity();

  final PreferencesRepository _prefs;
  final DesktopDiscoveryService _discovery;
  final Connectivity _connectivity;

  Future<bool> isOnLocalNetwork() async {
    if (usesFilesystemGallery) return true;
    final results = await _connectivity.checkConnectivity();
    return results.any((r) =>
        r == ConnectivityResult.wifi || r == ConnectivityResult.ethernet);
  }

  Future<DesktopAvailabilityResult> check({bool discoverIfNeeded = true}) async {
    if (usesFilesystemGallery) {
      return const DesktopAvailabilityResult(
        available: false,
        reason: 'Desktop app does not upload to itself',
      );
    }

    if (!_prefs.backupEnabled) {
      return const DesktopAvailabilityResult(
        available: false,
        reason: 'Backup disabled',
      );
    }

    if (_prefs.backupAuthToken == null) {
      return const DesktopAvailabilityResult(
        available: false,
        reason: 'Not paired with a desktop',
      );
    }

    if (!await isOnLocalNetwork()) {
      return const DesktopAvailabilityResult(
        available: false,
        reason: 'Not on Wi-Fi',
      );
    }

    var host = _prefs.backupDesktopHost;
    var port = _prefs.backupDesktopPort;
    var deviceName = _prefs.pairedDesktopName;

    if (host != null && port != null) {
      final health = await _healthCheck(host, port, _prefs.backupAuthToken!);
      if (health != null && health.isReady && health.tokenValid) {
        return DesktopAvailabilityResult(
          available: true,
          host: host,
          port: port,
          deviceName: deviceName ?? health.deviceName,
        );
      }
    }

    if (!discoverIfNeeded) {
      return const DesktopAvailabilityResult(
        available: false,
        reason: 'Desktop not reachable',
      );
    }

    final discovered = await _discovery.discover();
    if (discovered == null) {
      return const DesktopAvailabilityResult(
        available: false,
        reason: 'Desktop not found on network',
      );
    }

    final token = _prefs.backupAuthToken!;
    final health = await _healthCheck(
      discovered.host,
      discovered.port,
      token,
    );

    if (health == null || !health.isReady || !health.tokenValid) {
      return DesktopAvailabilityResult(
        available: false,
        host: discovered.host,
        port: discovered.port,
        reason: health?.tokenValid == false
            ? 'Pairing token rejected'
            : 'Desktop not ready',
      );
    }

    await _prefs.setBackupDesktopHost(discovered.host);
    await _prefs.setBackupDesktopPort(discovered.port);
    if (discovered.deviceName.isNotEmpty) {
      await _prefs.setPairedDesktopName(discovered.deviceName);
    }

    return DesktopAvailabilityResult(
      available: true,
      host: discovered.host,
      port: discovered.port,
      deviceName: deviceName ?? discovered.deviceName,
    );
  }

  Future<HealthResponse?> _healthCheck(
    String host,
    int port,
    String token,
  ) async {
    try {
      final uri = Uri.http('$host:$port', '/v1/health');
      final response = await http
          .get(
            uri,
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;
      return HealthResponse.fromJson(BackupProtocol.decodeJson(response.body));
    } catch (e, stack) {
      debugPrint('Health check failed: $e\n$stack');
      return null;
    }
  }
}
