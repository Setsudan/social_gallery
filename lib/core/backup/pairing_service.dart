import 'dart:math';

import 'package:social_gallery/data/repositories/preferences_repository.dart';

/// One-time PIN pairing and token storage.
class PairingService {
  PairingService(this._prefs);

  final PreferencesRepository _prefs;
  final _random = Random.secure();

  String? _activePin;
  DateTime? _pinExpiresAt;

  String? get activePin => _activePin;

  DateTime? get pinExpiresAt => _pinExpiresAt;

  bool get isPinActive =>
      _activePin != null &&
      _pinExpiresAt != null &&
      DateTime.now().isBefore(_pinExpiresAt!);

  String generatePin() {
    final pin = (_random.nextInt(900000) + 100000).toString();
    _activePin = pin;
    _pinExpiresAt = DateTime.now().add(const Duration(minutes: 10));
    return pin;
  }

  void clearPin() {
    _activePin = null;
    _pinExpiresAt = null;
  }

  bool validatePin(String pin) {
    if (!isPinActive) return false;
    return _activePin == pin.trim();
  }

  String createToken() {
    final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  bool isValidToken(String? token) {
    if (token == null || token.isEmpty) return false;
    final stored = _prefs.backupAuthToken;
    return stored != null && stored == token;
  }

  Future<void> savePairing({
    required String token,
    required String desktopId,
    required String desktopName,
    required String host,
    required int port,
    required String mobileDeviceName,
  }) async {
    await _prefs.setBackupAuthToken(token);
    await _prefs.setPairedDesktopId(desktopId);
    await _prefs.setPairedDesktopName(desktopName);
    await _prefs.setBackupDesktopHost(host);
    await _prefs.setBackupDesktopPort(port);
    await _prefs.setPairedMobileDeviceName(mobileDeviceName);
    await _prefs.setBackupEnabled(true);
  }

  Future<void> clearPairing() async {
    await _prefs.clearBackupPairing();
  }

  Future<void> clearDesktopReceiverPairing() async {
    await _prefs.clearDesktopReceiverPairing();
    clearPin();
  }

  bool get isDesktopReceiverPaired =>
      _prefs.backupAuthToken != null && _prefs.pairedMobileDeviceName != null;

  Future<void> saveDesktopReceiverToken({
    required String token,
    required String desktopId,
    required String mobileDeviceName,
  }) async {
    await _prefs.setBackupAuthToken(token);
    await _prefs.setPairedDesktopId(desktopId);
    await _prefs.setPairedMobileDeviceName(mobileDeviceName);
  }

  bool get isPaired =>
      _prefs.backupAuthToken != null && _prefs.pairedDesktopId != null;
}
