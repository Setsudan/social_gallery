import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Access/secret keys for S3-compatible cloud backup.
class CloudCredentialStore {
  CloudCredentialStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessKey = 'cloud_backup_access_key';
  static const _secretKey = 'cloud_backup_secret_key';

  final FlutterSecureStorage _storage;

  Future<String?> readAccessKey() => _storage.read(key: _accessKey);
  Future<String?> readSecretKey() => _storage.read(key: _secretKey);

  Future<void> save({
    required String accessKey,
    required String secretKey,
  }) async {
    await _storage.write(key: _accessKey, value: accessKey);
    await _storage.write(key: _secretKey, value: secretKey);
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _secretKey);
  }

  Future<bool> hasCredentials() async {
    final a = await readAccessKey();
    final s = await readSecretKey();
    return a != null && a.isNotEmpty && s != null && s.isNotEmpty;
  }
}
