import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:social_gallery/core/media/jxl_codec.dart';

/// Bundle of thumbnail metrics computed from a single decode.
class ImageMetricsBundle {
  const ImageMetricsBundle({
    required this.dHash,
    required this.blurScore,
    required this.exposureScore,
    required this.isSolidColor,
    required this.dominantColor,
  });

  final String dHash;
  final double blurScore;
  final double exposureScore;
  final bool isSolidColor;
  final String? dominantColor;
}

/// Decodes [bytes] once and computes all search/quality metrics.
ImageMetricsBundle? computeAllImageMetrics(Uint8List bytes) {
  final decoded = decodeRasterImage(bytes);
  if (decoded == null) return null;

  return ImageMetricsBundle(
    dHash: _dHashFromImage(decoded),
    blurScore: _blurScoreFromImage(decoded),
    exposureScore: _exposureScoreFromImage(decoded),
    isSolidColor: _isSolidColorFromImage(decoded),
    dominantColor: _dominantColorFromImage(decoded),
  );
}

String computeDHash(Uint8List bytes) {
  final decoded = decodeRasterImage(bytes);
  if (decoded == null) return '';
  return _dHashFromImage(decoded);
}

double computeBlurScore(Uint8List bytes) {
  final decoded = decodeRasterImage(bytes);
  if (decoded == null) return 0;
  return _blurScoreFromImage(decoded);
}

double computeExposureScore(Uint8List bytes) {
  final decoded = decodeRasterImage(bytes);
  if (decoded == null) return 128;
  return _exposureScoreFromImage(decoded);
}

bool computeIsSolidColor(Uint8List bytes) {
  final decoded = decodeRasterImage(bytes);
  if (decoded == null) return false;
  return _isSolidColorFromImage(decoded);
}

String _dHashFromImage(img.Image decoded) {
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

double _blurScoreFromImage(img.Image decoded) {
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

double _exposureScoreFromImage(img.Image decoded) {
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

bool _isSolidColorFromImage(img.Image decoded) {
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

/// Named color buckets used for search filters.
const kColorBuckets = [
  'red',
  'orange',
  'yellow',
  'green',
  'teal',
  'blue',
  'purple',
  'pink',
  'brown',
  'black',
  'white',
  'gray',
];

/// Maps average thumbnail RGB to a [kColorBuckets] id, or null if undecodable.
String? computeDominantColor(Uint8List bytes) {
  final decoded = decodeRasterImage(bytes);
  if (decoded == null) return null;
  return _dominantColorFromImage(decoded);
}

String? _dominantColorFromImage(img.Image decoded) {
  final sample = img.copyResize(decoded, width: 32, height: 32);
  var rSum = 0.0;
  var gSum = 0.0;
  var bSum = 0.0;
  final count = sample.width * sample.height;

  for (var y = 0; y < sample.height; y++) {
    for (var x = 0; x < sample.width; x++) {
      final p = sample.getPixel(x, y);
      rSum += p.r;
      gSum += p.g;
      bSum += p.b;
    }
  }

  return rgbToColorBucket(
    (rSum / count).round(),
    (gSum / count).round(),
    (bSum / count).round(),
  );
}

/// Pure helper for unit tests and [computeDominantColor].
String rgbToColorBucket(int r, int g, int b) {
  final maxC = [r, g, b].reduce((a, c) => a > c ? a : c);
  final minC = [r, g, b].reduce((a, c) => a < c ? a : c);
  final delta = maxC - minC;

  final lightness = maxC / 255.0;
  if (lightness < 0.15) return 'black';
  if (lightness > 0.92 && delta < 30) return 'white';
  if (delta < 25) return 'gray';

  final saturation = maxC == 0 ? 0.0 : delta / maxC;
  if (saturation < 0.12) {
    if (lightness < 0.35) return 'black';
    if (lightness > 0.85) return 'white';
    return 'gray';
  }

  var hue = 0.0;
  if (delta > 0) {
    if (maxC == r) {
      hue = 60 * (((g - b) / delta) % 6);
    } else if (maxC == g) {
      hue = 60 * (((b - r) / delta) + 2);
    } else {
      hue = 60 * (((r - g) / delta) + 4);
    }
  }
  if (hue < 0) hue += 360;

  if (hue < 15 || hue >= 345) return 'red';
  if (hue < 40) return r > g * 1.2 ? 'orange' : 'brown';
  if (hue < 65) return 'yellow';
  if (hue < 150) return 'green';
  if (hue < 185) return 'teal';
  if (hue < 250) return 'blue';
  if (hue < 290) return 'purple';
  if (hue < 330) return 'pink';
  return 'red';
}
