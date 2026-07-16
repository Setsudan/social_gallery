import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

class FilesystemImageDimensions {
  const FilesystemImageDimensions({
    required this.width,
    required this.height,
  });

  final int width;
  final int height;
}

/// Bytes typically enough for codec headers / EXIF dimension probes.
const _headerProbeBytes = 256 * 1024;

Future<Uint8List?> _readFilePrefix(File file, {int maxBytes = _headerProbeBytes}) async {
  final length = await file.length();
  if (length <= 0) return null;
  final raf = await file.open();
  try {
    final toRead = length < maxBytes ? length : maxBytes;
    return await raf.read(toRead);
  } finally {
    await raf.close();
  }
}

Future<FilesystemImageDimensions?> readFilesystemImageDimensions(
  String path,
) async {
  try {
    final file = File(path);
    if (!file.existsSync()) return null;

    // Prefer a bounded header read; fall back to full file for exotic formats.
    final prefix = await _readFilePrefix(file);
    if (prefix != null) {
      final fromPrefix = await _dimensionsFromBytes(prefix);
      if (fromPrefix != null) return fromPrefix;
    }
    return _dimensionsFromBytes(await file.readAsBytes());
  } catch (_) {
    return null;
  }
}

Future<FilesystemImageDimensions?> _dimensionsFromBytes(Uint8List bytes) async {
  if (bytes.isEmpty) return null;

  ui.Codec? codec;
  try {
    codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    try {
      return FilesystemImageDimensions(
        width: frame.image.width,
        height: frame.image.height,
      );
    } finally {
      frame.image.dispose();
    }
  } catch (_) {
    return null;
  } finally {
    codec?.dispose();
  }
}

Future<Uint8List?> readFilesystemThumbnailBytes(
  String path, {
  int maxEdge = 256,
}) async {
  try {
    final file = File(path);
    if (!file.existsSync()) return null;

    // Decode with target size so Flutter downsamples during decode.
    // Read full file only when needed for thumbnail generation (bounded by codec).
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return null;

    ui.Codec? codec;
    try {
      codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: maxEdge,
        targetHeight: maxEdge,
      );
      final frame = await codec.getNextFrame();
      try {
        final data = await frame.image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        return data?.buffer.asUint8List();
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec?.dispose();
    }
  } catch (_) {
    return null;
  }
}
