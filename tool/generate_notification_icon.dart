import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  final sourceBytes =
      File('assets/icons/app_icon_dark.png').readAsBytesSync();
  final source = img.decodePng(sourceBytes);
  if (source == null) {
    stderr.writeln('Failed to decode app_icon_dark.png');
    exit(1);
  }

  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      final pixel = source.getPixel(x, y);
      final luminance = (pixel.r + pixel.g + pixel.b) / 3;
      if (luminance < 128) {
        source.setPixelRgba(x, y, 0, 0, 0, 0);
      } else {
        source.setPixelRgba(x, y, 255, 255, 255, 255);
      }
    }
  }

  const sizes = {
    'drawable-mdpi': 24,
    'drawable-hdpi': 36,
    'drawable-xhdpi': 48,
    'drawable-xxhdpi': 72,
    'drawable-xxxhdpi': 96,
  };

  for (final entry in sizes.entries) {
    final dir = Directory('android/app/src/main/res/${entry.key}');
    dir.createSync(recursive: true);
    final resized = img.copyResize(
      source,
      width: entry.value,
      height: entry.value,
      interpolation: img.Interpolation.cubic,
    );
    File('${dir.path}/ic_notification.png')
        .writeAsBytesSync(img.encodePng(resized));
    stdout.writeln('Wrote ${dir.path}/ic_notification.png');
  }
}
