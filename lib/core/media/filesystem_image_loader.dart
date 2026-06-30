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

Future<FilesystemImageDimensions?> readFilesystemImageDimensions(
  String path,
) async {
  try {
    final file = File(path);
    if (!file.existsSync()) return null;
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
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return null;

    ui.Codec? codec;
    try {
      codec = await ui.instantiateImageCodec(bytes, targetWidth: maxEdge);
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
