import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:pointycastle/export.dart';

/// Chunked AES-256-GCM container for cloud backup (video-safe, streaming).
///
/// Layout:
/// - magic (8) "SGVAULT2"
/// - version (1) = 1
/// - chunkSize (4 BE)
/// - originalSize (8 BE)
/// - nameLen (2 BE) + utf8 name
/// - mimeLen (2 BE) + utf8 mime
/// - repeated: nonce(12) + cipherLen(4 BE) + ciphertext+tag
class StreamingVaultCryptor {
  StreamingVaultCryptor({this.chunkSize = 4 * 1024 * 1024});

  static const magic = 'SGVAULT2';
  static const version = 1;
  static const _nonceLength = 12;
  static const _tagBits = 128;

  final int chunkSize;

  /// Streams [plainPath] into an encrypted file at [outputPath].
  Future<({String checksum, int cipherSize})> encryptFile({
    required String plainPath,
    required String outputPath,
    required Uint8List encryptionKey,
    required String fileName,
    required String mimeType,
  }) async {
    final plain = File(plainPath);
    final originalSize = await plain.length();
    final outFile = File(outputPath);
    await outFile.parent.create(recursive: true);
    final sink = outFile.openWrite();

    try {
      sink.add(utf8.encode(magic));
      sink.add([version]);
      sink.add(_uint32Bytes(chunkSize));
      sink.add(_uint64Bytes(originalSize));

      final nameBytes = utf8.encode(fileName);
      final mimeBytes = utf8.encode(mimeType);
      if (nameBytes.length > 0xffff || mimeBytes.length > 0xffff) {
        throw ArgumentError('Name or mime too long');
      }
      sink.add(_uint16Bytes(nameBytes.length));
      sink.add(nameBytes);
      sink.add(_uint16Bytes(mimeBytes.length));
      sink.add(mimeBytes);

      final raf = await plain.open();
      try {
        var remaining = originalSize;
        while (remaining > 0) {
          final toRead = remaining > chunkSize ? chunkSize : remaining;
          final plainChunk = await raf.read(toRead);
          remaining -= plainChunk.length;

          final nonce = _randomBytes(_nonceLength);
          final cipher = GCMBlockCipher(AESEngine())
            ..init(
              true,
              AEADParameters(
                KeyParameter(encryptionKey),
                _tagBits,
                nonce,
                Uint8List(0),
              ),
            );
          final encrypted = cipher.process(Uint8List.fromList(plainChunk));
          sink.add(nonce);
          sink.add(_uint32Bytes(encrypted.length));
          sink.add(encrypted);
        }
      } finally {
        await raf.close();
      }
    } finally {
      await sink.close();
    }

    final checksum = await sha256File(plainPath);
    final cipherSize = await outFile.length();
    return (checksum: checksum, cipherSize: cipherSize);
  }

  /// Decrypts [vaultPath] to a temp plain file. Returns path + metadata.
  Future<({File file, String fileName, String mimeType, int originalSize})>
      decryptToTempFile({
    required String vaultPath,
    required Uint8List encryptionKey,
  }) async {
    final raf = await File(vaultPath).open();
    try {
      final magicBytes = await raf.read(magic.length);
      if (utf8.decode(magicBytes) != magic) {
        throw FormatException('Invalid SGVAULT2 magic');
      }
      final ver = (await raf.read(1)).first;
      if (ver != version) {
        throw FormatException('Unsupported SGVAULT2 version $ver');
      }
      final storedChunkSize = _readUint32(await raf.read(4));
      final originalSize = _readUint64(await raf.read(8));
      final nameLen = _readUint16(await raf.read(2));
      final fileName = utf8.decode(await raf.read(nameLen));
      final mimeLen = _readUint16(await raf.read(2));
      final mimeType = utf8.decode(await raf.read(mimeLen));

      final tempDir = await Directory.systemTemp.createTemp('sg_cloud_vault_');
      final outPath = p.join(tempDir.path, fileName);
      final out = File(outPath).openWrite();
      var written = 0;
      try {
        while (written < originalSize) {
          final nonce = await raf.read(_nonceLength);
          if (nonce.length < _nonceLength) break;
          final cipherLen = _readUint32(await raf.read(4));
          final encrypted = await raf.read(cipherLen);
          final cipher = GCMBlockCipher(AESEngine())
            ..init(
              false,
              AEADParameters(
                KeyParameter(encryptionKey),
                _tagBits,
                Uint8List.fromList(nonce),
                Uint8List(0),
              ),
            );
          final plain = cipher.process(Uint8List.fromList(encrypted));
          out.add(plain);
          written += plain.length;
        }
      } finally {
        await out.close();
      }

      if (written != originalSize) {
        throw FormatException(
          'Decrypted size $written != expected $originalSize '
          '(chunkSize hint $storedChunkSize)',
        );
      }
      return (
        file: File(outPath),
        fileName: fileName,
        mimeType: mimeType,
        originalSize: originalSize,
      );
    } finally {
      await raf.close();
    }
  }

  /// Streaming SHA-256 of a plaintext file.
  static Future<String> sha256File(String path) async {
    final digest = await sha256.bind(File(path).openRead()).first;
    return digest.toString();
  }

  Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(length, (_) => random.nextInt(256)),
    );
  }

  Uint8List _uint16Bytes(int value) =>
      Uint8List(2)..buffer.asByteData().setUint16(0, value, Endian.big);

  Uint8List _uint32Bytes(int value) =>
      Uint8List(4)..buffer.asByteData().setUint32(0, value, Endian.big);

  Uint8List _uint64Bytes(int value) =>
      Uint8List(8)..buffer.asByteData().setUint64(0, value, Endian.big);

  int _readUint16(List<int> bytes) =>
      ByteData.sublistView(Uint8List.fromList(bytes)).getUint16(0, Endian.big);

  int _readUint32(List<int> bytes) =>
      ByteData.sublistView(Uint8List.fromList(bytes)).getUint32(0, Endian.big);

  int _readUint64(List<int> bytes) =>
      ByteData.sublistView(Uint8List.fromList(bytes)).getUint64(0, Endian.big);
}
