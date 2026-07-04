import 'package:flutter_test/flutter_test.dart';
import 'package:social_gallery/core/analysis/image_metrics.dart';

void main() {
  group('rgbToColorBucket', () {
    test('maps saturated hues', () {
      expect(rgbToColorBucket(220, 20, 20), 'red');
      expect(rgbToColorBucket(240, 140, 20), 'orange');
      expect(rgbToColorBucket(240, 220, 20), 'yellow');
      expect(rgbToColorBucket(20, 180, 40), 'green');
      expect(rgbToColorBucket(20, 160, 180), 'blue');
      expect(rgbToColorBucket(20, 60, 220), 'blue');
      expect(rgbToColorBucket(120, 20, 180), 'purple');
    });

    test('maps neutrals', () {
      expect(rgbToColorBucket(10, 10, 10), 'black');
      expect(rgbToColorBucket(245, 245, 245), 'white');
      expect(rgbToColorBucket(120, 120, 120), 'gray');
      expect(rgbToColorBucket(100, 85, 70), 'brown');
    });
  });

  group('kColorBuckets', () {
    test('contains expected buckets', () {
      expect(kColorBuckets, contains('red'));
      expect(kColorBuckets, contains('blue'));
      expect(kColorBuckets.length, 12);
    });
  });
}
