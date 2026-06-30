/// Deep link payload for pairing mobile with desktop backup receiver.
class BackupPairingParams {
  const BackupPairingParams({
    required this.address,
    required this.port,
    required this.pin,
  });

  final String address;
  final int port;
  final String pin;
}

/// Builds and parses `socialgallery://pair?ip=...&port=...&pin=...` links.
class BackupDeepLink {
  BackupDeepLink._();

  static const scheme = 'socialgallery';
  static const pairHost = 'pair';

  static Uri pairingUri({
    required String address,
    required int port,
    required String pin,
  }) {
    return Uri(
      scheme: scheme,
      host: pairHost,
      queryParameters: {
        'ip': address,
        'port': port.toString(),
        'pin': pin,
      },
    );
  }

  static BackupPairingParams? parse(Uri uri) {
    if (uri.scheme != scheme) return null;
    if (uri.host != pairHost) return null;

    final address = uri.queryParameters['ip'] ?? uri.queryParameters['host'];
    final portRaw = uri.queryParameters['port'];
    final pin = uri.queryParameters['pin'];
    if (address == null || portRaw == null || pin == null) return null;

    final port = int.tryParse(portRaw);
    if (port == null || pin.length != 6) return null;

    return BackupPairingParams(address: address, port: port, pin: pin);
  }

  /// Accepts deep links and legacy JSON QR payloads.
  static BackupPairingParams? parsePayload(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('$scheme://')) {
      return parse(Uri.parse(trimmed));
    }

    try {
      final uri = Uri.tryParse(trimmed);
      if (uri != null && uri.scheme == scheme) {
        return parse(uri);
      }
    } catch (_) {}

    try {
      final decoded = Uri.decodeComponent(trimmed);
      if (decoded.startsWith('$scheme://')) {
        return parse(Uri.parse(decoded));
      }
    } catch (_) {}

    return null;
  }
}
