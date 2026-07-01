import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Mobile-side secure storage for the vault backup password.
class VaultPasswordStore {
  VaultPasswordStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'desktop_vault_password';

  final FlutterSecureStorage _storage;

  Future<bool> hasPassword() async {
    final value = await _storage.read(key: _key);
    return value != null && value.isNotEmpty;
  }

  Future<String?> readPassword() => _storage.read(key: _key);

  Future<void> savePassword(String password) async {
    await _storage.write(key: _key, value: password);
  }

  Future<void> clearPassword() async {
    await _storage.delete(key: _key);
  }
}
