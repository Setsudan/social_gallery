import 'package:flutter_test/flutter_test.dart';
import 'package:social_gallery/features/discover/duplicate_scan_controller.dart';

void main() {
  group('DuplicateScanState', () {
    test('progress is zero when total is zero', () {
      const state = DuplicateScanState(scanned: 5, total: 0);
      expect(state.progress, 0);
    });

    test('progress reflects scanned over total', () {
      const state = DuplicateScanState(scanned: 3, total: 10);
      expect(state.progress, 0.3);
    });

    test('isComplete when groups are set and not scanning', () {
      const state = DuplicateScanState(groups: [], isScanning: false);
      expect(state.isComplete, isTrue);
    });

    test('isComplete is false while scanning', () {
      const state = DuplicateScanState(
        groups: [],
        isScanning: true,
        scanned: 1,
        total: 5,
      );
      expect(state.isComplete, isFalse);
    });

    test('isComplete is false before first result', () {
      const state = DuplicateScanState();
      expect(state.isComplete, isFalse);
    });
  });
}
