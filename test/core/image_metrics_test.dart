import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:social_gallery/core/analysis/image_metrics.dart';

Uint8List _solidImageBytes() {
  final image = img.Image(width: 32, height: 32);
  img.fill(image, color: img.ColorRgb8(128, 128, 128));
  return Uint8List.fromList(img.encodeJpg(image));
}

Uint8List _noisyImageBytes() {
  final image = img.Image(width: 64, height: 64);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final v = (x * 17 + y * 31) % 256;
      image.setPixel(x, y, img.ColorRgb8(v, (v + 40) % 256, (v + 80) % 256));
    }
  }
  return Uint8List.fromList(img.encodeJpg(image));
}

void main() {
  test('dHash is stable for identical images', () {
    final bytes = _solidImageBytes();
    final a = computeDHash(bytes);
    final b = computeDHash(bytes);
    expect(a, b);
    expect(a.length, 64);
  });

  test('solid color detection', () {
    expect(computeIsSolidColor(_solidImageBytes()), isTrue);
    expect(computeIsSolidColor(_noisyImageBytes()), isFalse);
  });

  test('noisy image has higher blur score than flat image', () {
    final flat = computeBlurScore(_solidImageBytes());
    final noisy = computeBlurScore(_noisyImageBytes());
    expect(noisy, greaterThan(flat));
  });
}
