import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pointycastle/export.dart';
import 'package:social_gallery/core/cloud_backup/cloud_vault_key_store.dart';
import 'package:social_gallery/core/cloud_backup/streaming_vault_cryptor.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sgvault2_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Uint8List deriveKey(String password, Uint8List salt) {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, CloudVaultKeyStore.pbkdf2Iterations, 32));
    return pbkdf2.process(Uint8List.fromList(utf8.encode(password)));
  }

  test('encrypt/decrypt round-trip for multi-chunk file', () async {
    final cryptor = StreamingVaultCryptor(chunkSize: 64);
    final plainPath = p.join(tempDir.path, 'plain.bin');
    final cipherPath = p.join(tempDir.path, 'out.sgvault2');
    final payload = Uint8List.fromList(
      List.generate(200, (i) => i % 256),
    );
    await File(plainPath).writeAsBytes(payload);

    final salt = Uint8List.fromList(List.generate(32, (i) => i + 1));
    final key = deriveKey('test-password-123', salt);

    final result = await cryptor.encryptFile(
      plainPath: plainPath,
      outputPath: cipherPath,
      encryptionKey: key,
      fileName: 'plain.bin',
      mimeType: 'application/octet-stream',
    );

    expect(result.cipherSize, greaterThan(payload.length));
    expect(result.checksum, isNotEmpty);

    final decrypted = await cryptor.decryptToTempFile(
      vaultPath: cipherPath,
      encryptionKey: key,
    );
    final roundTrip = await decrypted.file.readAsBytes();
    expect(roundTrip, payload);
    expect(decrypted.fileName, 'plain.bin');
  });

  test('sha256File matches known digest length', () async {
    final path = p.join(tempDir.path, 'a.txt');
    await File(path).writeAsString('hello');
    final hash = await StreamingVaultCryptor.sha256File(path);
    expect(hash.length, 64);
  });
}
