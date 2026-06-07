import 'dart:typed_data';

import 'package:image/image.dart' as img;

String computeDHash(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return '';

  final resized = img.copyResize(decoded, width: 9, height: 8);
  final gray = img.grayscale(resized);
  final buffer = StringBuffer();

  for (var y = 0; y < 8; y++) {
    for (var x = 0; x < 8; x++) {
      final left = gray.getPixel(x, y).r;
      final right = gray.getPixel(x + 1, y).r;
      buffer.write(left < right ? '1' : '0');
    }
  }
  return buffer.toString();
}

double computeBlurScore(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return 0;

  final gray = img.grayscale(img.copyResize(decoded, width: 64, height: 64));
  var sum = 0.0;
  var sumSq = 0.0;
  var count = 0;

  for (var y = 1; y < gray.height - 1; y++) {
    for (var x = 1; x < gray.width - 1; x++) {
      final center = gray.getPixel(x, y).r.toDouble();
      final left = gray.getPixel(x - 1, y).r.toDouble();
      final right = gray.getPixel(x + 1, y).r.toDouble();
      final up = gray.getPixel(x, y - 1).r.toDouble();
      final down = gray.getPixel(x, y + 1).r.toDouble();
      final laplacian = (4 * center) - left - right - up - down;
      sum += laplacian;
      sumSq += laplacian * laplacian;
      count++;
    }
  }

  if (count == 0) return 0;
  final mean = sum / count;
  final variance = (sumSq / count) - (mean * mean);
  return variance;
}

double computeExposureScore(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return 128;

  final gray = img.grayscale(img.copyResize(decoded, width: 32, height: 32));
  var total = 0.0;
  final pixels = gray.width * gray.height;
  for (var y = 0; y < gray.height; y++) {
    for (var x = 0; x < gray.width; x++) {
      total += gray.getPixel(x, y).r;
    }
  }
  return total / pixels;
}

bool computeIsSolidColor(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return false;

  final sample = img.copyResize(decoded, width: 16, height: 16);
  final first = sample.getPixel(0, 0);
  var same = 0;
  final total = sample.width * sample.height;

  for (var y = 0; y < sample.height; y++) {
    for (var x = 0; x < sample.width; x++) {
      final p = sample.getPixel(x, y);
      if ((p.r - first.r).abs() < 8 &&
          (p.g - first.g).abs() < 8 &&
          (p.b - first.b).abs() < 8) {
        same++;
      }
    }
  }
  return same / total > 0.95;
}
