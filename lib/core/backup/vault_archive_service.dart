import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:pointycastle/export.dart';
import 'package:social_gallery/core/backup/desktop_backup_inventory.dart';

/// Creates password-protected AES-256 encrypted zip archives for vault storage.
class VaultArchiveService {
  static const _magic = 'SGVAULT1';
  static const _nonceLength = 12;

  static String vaultRelativePath(String folderName, String fileName) {
    final safeFolder = DesktopBackupInventory.sanitizeFolderName(folderName);
    final safeName = DesktopBackupInventory.sanitizeFileName(fileName);
    final base = p.basenameWithoutExtension(safeName);
    final ext = p.extension(safeName);
    return '.social_gallery/vault/$safeFolder/$base$ext.zip';
  }

  /// Encrypts [plainPath] into an AES-256-GCM protected zip at [outputPath].
  Future<void> encryptToVaultArchive({
    required String plainPath,
    required String outputPath,
    required Uint8List encryptionKey,
    required String innerFileName,
  }) async {
    final plainBytes = await File(plainPath).readAsBytes();

    final archive = Archive()
      ..addFile(
        ArchiveFile(
          innerFileName,
          plainBytes.length,
          plainBytes,
        ),
      );
    final zipBytes = ZipEncoder().encode(archive);

    final nonce = _randomBytes(_nonceLength);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true,
        AEADParameters(
          KeyParameter(encryptionKey),
          128,
          nonce,
          Uint8List(0),
        ),
      );

    final encrypted = cipher.process(Uint8List.fromList(zipBytes));
    final innerNameBytes = utf8.encode(innerFileName);

    final output = BytesBuilder();
    output.add(utf8.encode(_magic));
    output.add(nonce);
    output.add(_uint32Bytes(innerNameBytes.length));
    output.add(innerNameBytes);
    output.add(_uint64Bytes(plainBytes.length));
    output.add(encrypted);

    final outFile = File(outputPath);
    await outFile.parent.create(recursive: true);
    await outFile.writeAsBytes(output.toBytes());
  }

  /// Decrypts a vault archive to a temporary plain file for streaming/thumbnails.
  Future<File> decryptToTempFile({
    required String vaultPath,
    required Uint8List encryptionKey,
  }) async {
    final payload = await _readPayload(vaultPath, encryptionKey);
    final tempDir = Directory.systemTemp.createTempSync('sg_vault_');
    final outPath = p.join(tempDir.path, payload.innerFileName);
    await File(outPath).writeAsBytes(payload.plainBytes, flush: true);
    return File(outPath);
  }

  /// Opens a readable stream for a byte range of the decrypted inner file.
  Future<VaultPlainPayload> readPlainPayload({
    required String vaultPath,
    required Uint8List encryptionKey,
  }) {
    return _readPayload(vaultPath, encryptionKey);
  }

  Future<VaultPlainPayload> _readPayload(
    String vaultPath,
    Uint8List encryptionKey,
  ) async {
    final bytes = await File(vaultPath).readAsBytes();
    var offset = 0;

    final magic = utf8.decode(bytes.sublist(offset, offset + _magic.length));
    offset += _magic.length;
    if (magic != _magic) {
      throw FormatException('Invalid vault archive');
    }

    final nonce = bytes.sublist(offset, offset + _nonceLength);
    offset += _nonceLength;

    final nameLength = _readUint32(bytes, offset);
    offset += 4;
    final innerFileName = utf8.decode(bytes.sublist(offset, offset + nameLength));
    offset += nameLength;

    final originalSize = _readUint64(bytes, offset);
    offset += 8;

    final encrypted = bytes.sublist(offset);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        false,
        AEADParameters(
          KeyParameter(encryptionKey),
          128,
          nonce,
          Uint8List(0),
        ),
      );

    final zipBytes = cipher.process(Uint8List.fromList(encrypted));
    final archive = ZipDecoder().decodeBytes(zipBytes);
    if (archive.files.isEmpty) {
      throw FormatException('Empty vault archive');
    }

    final entry = archive.files.first;
    final content = entry.content as List<int>;

    return VaultPlainPayload(
      innerFileName: innerFileName,
      plainBytes: Uint8List.fromList(content),
      originalSize: originalSize,
    );
  }

  Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(length, (_) => random.nextInt(256)),
    );
  }

  Uint8List _uint32Bytes(int value) {
    return Uint8List(4)
      ..buffer.asByteData().setUint32(0, value, Endian.big);
  }

  Uint8List _uint64Bytes(int value) {
    return Uint8List(8)
      ..buffer.asByteData().setUint64(0, value, Endian.big);
  }

  int _readUint32(Uint8List bytes, int offset) {
    return bytes.buffer.asByteData().getUint32(offset, Endian.big);
  }

  int _readUint64(Uint8List bytes, int offset) {
    return bytes.buffer.asByteData().getUint64(offset, Endian.big);
  }
}

class VaultPlainPayload {
  const VaultPlainPayload({
    required this.innerFileName,
    required this.plainBytes,
    required this.originalSize,
  });

  final String innerFileName;
  final Uint8List plainBytes;
  final int originalSize;
}
