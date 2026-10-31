import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:koni_jxl_flutter/koni_jxl_flutter.dart';
import 'package:path/path.dart' as p;

/// True when [path] has a `.jxl` extension.
bool isJxlPath(String path) {
  return p.extension(path).toLowerCase() == '.jxl';
}

/// Content sniff for JPEG XL (bare codestream or container).
bool isJxlBytes(List<int> bytes) => looksLikeJxl(bytes);

/// Header-only dimensions; returns null on malformed input.
({int width, int height})? readJxlDimensions(Uint8List bytes) {
  try {
    final info = JxlInfo.parse(bytes);
    return (width: info.width, height: info.height);
  } catch (_) {
    return null;
  }
}

/// Decodes JPEG XL [bytes] into a [package:image] raster for analysis/thumbs.
img.Image? decodeJxlToPackageImage(
  Uint8List bytes, {
  int? targetWidth,
  int? targetHeight,
}) {
  try {
    final decoded = JxlDecoder.decode(
      bytes,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
    final rgba = decoded.toRgba8();
    return img.Image.fromBytes(
      width: decoded.width,
      height: decoded.height,
      bytes: rgba.buffer,
      numChannels: 4,
      order: img.ChannelOrder.rgba,
    );
  } catch (_) {
    return null;
  }
}

/// Decodes any supported raster, including JPEG XL, to [package:image].
img.Image? decodeRasterImage(
  Uint8List bytes, {
  int? targetWidth,
  int? targetHeight,
}) {
  if (looksLikeJxl(bytes)) {
    return decodeJxlToPackageImage(
      bytes,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
  }
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  if (targetWidth == null && targetHeight == null) return decoded;
  return img.copyResize(decoded, width: targetWidth, height: targetHeight);
}

/// Instantiates a [ui.Codec], routing JPEG XL through koni_jxl.
Future<ui.Codec> instantiateRasterCodec(
  Uint8List bytes, {
  int? targetWidth,
  int? targetHeight,
}) async {
  if (looksLikeJxl(bytes)) {
    return decodeJxlToUiCodec(
      bytes,
      cacheWidth: targetWidth,
      cacheHeight: targetHeight,
    );
  }
  return ui.instantiateImageCodec(
    bytes,
    targetWidth: targetWidth,
    targetHeight: targetHeight,
  );
}

/// [Image] for a filesystem path, using [JxlImageProvider] when needed.
Widget buildFilesystemImage({
  required File file,
  BoxFit fit = BoxFit.cover,
  int? cacheWidth,
  int? cacheHeight,
  FilterQuality filterQuality = FilterQuality.low,
  bool gaplessPlayback = false,
  ImageErrorWidgetBuilder? errorBuilder,
}) {
  if (isJxlPath(file.path)) {
    return Image(
      image: JxlImageProvider.file(
        file,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
      ),
      fit: fit,
      filterQuality: filterQuality,
      gaplessPlayback: gaplessPlayback,
      errorBuilder: errorBuilder,
    );
  }
  return Image.file(
    file,
    fit: fit,
    cacheWidth: cacheWidth,
    cacheHeight: cacheHeight,
    filterQuality: filterQuality,
    gaplessPlayback: gaplessPlayback,
    errorBuilder: errorBuilder,
  );
}
