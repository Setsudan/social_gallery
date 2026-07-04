import 'package:flutter_test/flutter_test.dart';
import 'package:social_gallery/core/analysis/desktop_image_labeler.dart';

void main() {
  group('normalizeLabel', () {
    test('lowercases and trims', () {
      expect(normalizeLabel('  Egyptian cat '), 'egyptian cat');
    });
  });

  group('mergeNormalizedLabels', () {
    test('deduplicates case-insensitively', () {
      expect(
        mergeNormalizedLabels(['Cat', 'cat', 'Dog', '']),
        ['cat', 'dog'],
      );
    });
  });
}
