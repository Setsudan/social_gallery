import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:social_gallery/core/backup/backup_protocol.dart';
import 'package:social_gallery/core/backup/vault_archive_service.dart';
import 'package:social_gallery/core/backup/vault_config_store.dart';

void main() {
  group('BackupProtocol v2', () {
    test('BackupInitItem serializes isVault', () {
      const item = BackupInitItem(
        id: 1,
        name: 'photo.jpg',
        folderName: 'Private',
        size: 100,
        mime: 'image/jpeg',
        checksum: 'abc',
        isVault: true,
      );

      final json = item.toJson();
      expect(json['isVault'], isTrue);
    });

    test('HealthResponse parses capabilities', () {
      final response = HealthResponse.fromJson({
        'status': 'ready',
        'deviceName': 'Desktop',
        'protocolVersion': 2,
        'tokenValid': true,
        'capabilities': ['backup', 'library', 'vault'],
        'vaultConfigured': true,
      });

      expect(response.protocolVersion, 2);
      expect(response.supportsLibrary, isTrue);
      expect(response.vaultConfigured, isTrue);
    });
  });

  group('VaultArchiveService', () {
    late Directory tempDir;
    late VaultArchiveService service;
    late Uint8List key;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('vault_test_');
      service = VaultArchiveService();
      final config = VaultConfigStore(backupRoot: tempDir.path);
      await config.registerPassword('test-password-123');
      key = config.deriveEncryptionKey('test-password-123');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('round-trip encrypt and decrypt preserves bytes', () async {
      final plainPath = p.join(tempDir.path, 'plain.jpg');
      final vaultPath = p.join(tempDir.path, 'vault.zip');
      final original = List<int>.generate(4096, (i) => i % 256);
      await File(plainPath).writeAsBytes(original);

      await service.encryptToVaultArchive(
        plainPath: plainPath,
        outputPath: vaultPath,
        encryptionKey: key,
        innerFileName: 'plain.jpg',
      );

      expect(await File(vaultPath).exists(), isTrue);

      final payload = await service.readPlainPayload(
        vaultPath: vaultPath,
        encryptionKey: key,
      );

      expect(payload.plainBytes, original);
      expect(payload.innerFileName, 'plain.jpg');
    });

    test('wrong key fails decryption', () async {
      final plainPath = p.join(tempDir.path, 'plain.jpg');
      final vaultPath = p.join(tempDir.path, 'vault.zip');
      await File(plainPath).writeAsBytes([1, 2, 3, 4]);

      await service.encryptToVaultArchive(
        plainPath: plainPath,
        outputPath: vaultPath,
        encryptionKey: key,
        innerFileName: 'plain.jpg',
      );

      final wrongConfig = VaultConfigStore(backupRoot: p.join(tempDir.path, 'other'));
      await wrongConfig.registerPassword('other-password-456');
      final wrongKey = wrongConfig.deriveEncryptionKey('other-password-456');

      expect(
        () => service.readPlainPayload(
          vaultPath: vaultPath,
          encryptionKey: wrongKey,
        ),
        throwsA(anything),
      );
    });
  });

  group('VaultConfigStore', () {
    test('validatePassword accepts registered password', () async {
      final dir = await Directory.systemTemp.createTemp('vault_config_');
      final store = VaultConfigStore(backupRoot: dir.path);
      await store.registerPassword('secure-pass-99');

      expect(store.validatePassword('secure-pass-99'), isTrue);
      expect(store.validatePassword('wrong'), isFalse);

      await dir.delete(recursive: true);
    });
  });
}
