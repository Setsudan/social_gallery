import 'package:flutter_test/flutter_test.dart';
import 'package:social_gallery/shared/navigation/tab_scroll_to_top.dart';

void main() {
  group('shellNavLabelsExpandedForOffset', () {
    test('uses wider hysteresis band', () {
      expect(
        shellNavLabelsExpandedForOffset(0, currentlyExpanded: true),
        isTrue,
      );
      expect(
        shellNavLabelsExpandedForOffset(40, currentlyExpanded: true),
        isTrue,
      );
      expect(
        shellNavLabelsExpandedForOffset(72, currentlyExpanded: true),
        isFalse,
      );
      expect(
        shellNavLabelsExpandedForOffset(40, currentlyExpanded: false),
        isFalse,
      );
      expect(
        shellNavLabelsExpandedForOffset(8, currentlyExpanded: false),
        isTrue,
      );
    });
  });
}
