import 'package:flutter_test/flutter_test.dart';
import 'package:social_gallery/core/notifications/duplicate_scan_notification_throttle.dart';

void main() {
  group('shouldEmitDuplicateScanProgressNotification', () {
    test('emits for first and last items', () {
      expect(shouldEmitDuplicateScanProgressNotification(0, 100), isTrue);
      expect(shouldEmitDuplicateScanProgressNotification(100, 100), isTrue);
    });

    test('throttles intermediate updates to roughly 5 percent steps', () {
      const total = 100;
      final emitted = <int>[];
      for (var scanned = 0; scanned <= total; scanned++) {
        if (shouldEmitDuplicateScanProgressNotification(scanned, total)) {
          emitted.add(scanned);
        }
      }

      expect(emitted.first, 0);
      expect(emitted.last, 100);
      expect(emitted.length, lessThan(30));
    });

    test('emits preparing state when total is zero', () {
      expect(shouldEmitDuplicateScanProgressNotification(0, 0), isTrue);
      expect(shouldEmitDuplicateScanProgressNotification(1, 0), isFalse);
    });
  });
}
