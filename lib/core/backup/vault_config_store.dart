import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:pointycastle/export.dart';

/// Desktop-side vault password verifier (never stores plaintext password).
class VaultConfigStore {
  VaultConfigStore({required this.backupRoot});

  final String backupRoot;

  static const _hiddenDir = '.social_gallery';
  static const _configFile = 'vault-config.json';
  static const pbkdf2Iterations = 100000;
  static const _saltLength = 32;
  static const _keyLength = 32;

  String get _configPath =>
      p.join(backupRoot, _hiddenDir, _configFile);

  VaultConfig? _cached;

  bool get isConfigured => _cached != null;

  VaultConfig? get config => _cached;

  Future<void> load() async {
    _cached = null;
    final file = File(_configPath);
    if (!await file.exists()) return;
    try {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      _cached = VaultConfig.fromJson(json);
    } catch (_) {
      _cached = null;
    }
  }

  Future<void> registerPassword(String password) async {
    final salt = _randomBytes(_saltLength);
    final key = _deriveKey(password, salt);
    final verifierHash = sha256.convert(key).toString();

    _cached = VaultConfig(
      salt: base64Encode(salt),
      verifierHash: verifierHash,
    );

    final dir = Directory(p.join(backupRoot, _hiddenDir));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    await File(_configPath).writeAsString(
      jsonEncode(_cached!.toJson()),
    );
  }

  bool validatePassword(String password) {
    final config = _cached;
    if (config == null) return false;
    final key = _deriveKey(password, base64Decode(config.salt));
    return sha256.convert(key).toString() == config.verifierHash;
  }

  Uint8List deriveEncryptionKey(String password) {
    final config = _cached;
    if (config == null) {
      throw StateError('Vault is not configured');
    }
    if (!validatePassword(password)) {
      throw ArgumentError('Invalid vault password');
    }
    return _deriveKey(password, base64Decode(config.salt));
  }

  Uint8List _deriveKey(String password, Uint8List salt) {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, pbkdf2Iterations, _keyLength));
    return pbkdf2.process(Uint8List.fromList(utf8.encode(password)));
  }

  Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(length, (_) => random.nextInt(256)),
    );
  }
}

class VaultConfig {
  const VaultConfig({
    required this.salt,
    required this.verifierHash,
  });

  factory VaultConfig.fromJson(Map<String, dynamic> json) {
    return VaultConfig(
      salt: json['salt'] as String? ?? '',
      verifierHash: json['verifierHash'] as String? ?? '',
    );
  }

  final String salt;
  final String verifierHash;

  Map<String, dynamic> toJson() => {
    'salt': salt,
    'verifierHash': verifierHash,
  };
}
