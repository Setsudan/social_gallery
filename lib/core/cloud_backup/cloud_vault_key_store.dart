import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';

/// Key-value store used by [CloudVaultKeyStore] (secure storage or tests).
abstract class CloudSecureKv {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class FlutterCloudSecureKv implements CloudSecureKv {
  FlutterCloudSecureKv([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class MemoryCloudSecureKv implements CloudSecureKv {
  final Map<String, String> _map = {};

  @override
  Future<String?> read(String key) async => _map[key];

  @override
  Future<void> write(String key, String value) async => _map[key] = value;

  @override
  Future<void> delete(String key) async => _map.remove(key);
}

/// One-time PBKDF2 key setup for cloud encryption. Salt never rotates after register.
class CloudVaultKeyStore {
  CloudVaultKeyStore({CloudSecureKv? storage})
      : _storage = storage ?? FlutterCloudSecureKv();

  static const _passwordKey = 'cloud_vault_password';
  static const _saltKey = 'cloud_vault_salt_b64';
  static const _verifierKey = 'cloud_vault_verifier';
  static const pbkdf2Iterations = 100000;
  static const _saltLength = 32;
  static const _keyLength = 32;

  final CloudSecureKv _storage;

  Future<bool> isConfigured() async {
    final salt = await _storage.read(_saltKey);
    final verifier = await _storage.read(_verifierKey);
    return salt != null &&
        salt.isNotEmpty &&
        verifier != null &&
        verifier.isNotEmpty;
  }

  Future<bool> hasPassword() async {
    final value = await _storage.read(_passwordKey);
    return value != null && value.isNotEmpty;
  }

  Future<String?> readPassword() => _storage.read(_passwordKey);

  /// First-time setup only. Throws if already configured.
  Future<void> registerPassword(String password) async {
    if (password.length < 8) {
      throw ArgumentError('Password must be at least 8 characters');
    }
    if (await isConfigured()) {
      throw StateError('Cloud vault already configured; use unlock instead');
    }
    final salt = _randomBytes(_saltLength);
    final key = _deriveKey(password, salt);
    final verifier = sha256.convert(key).toString();
    await _storage.write(_saltKey, base64Encode(salt));
    await _storage.write(_verifierKey, verifier);
    await _storage.write(_passwordKey, password);
  }

  /// Validates password against stored verifier without rotating salt.
  Future<bool> unlock(String password) async {
    final saltB64 = await _storage.read(_saltKey);
    final verifier = await _storage.read(_verifierKey);
    if (saltB64 == null || verifier == null) return false;
    final key = _deriveKey(password, base64Decode(saltB64));
    if (sha256.convert(key).toString() != verifier) return false;
    await _storage.write(_passwordKey, password);
    return true;
  }

  Future<Uint8List?> deriveEncryptionKey() async {
    final password = await readPassword();
    final saltB64 = await _storage.read(_saltKey);
    final verifier = await _storage.read(_verifierKey);
    if (password == null || saltB64 == null || verifier == null) return null;
    final key = _deriveKey(password, base64Decode(saltB64));
    if (sha256.convert(key).toString() != verifier) return null;
    return key;
  }

  Future<void> clear() async {
    await _storage.delete(_passwordKey);
    await _storage.delete(_saltKey);
    await _storage.delete(_verifierKey);
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
