import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:social_gallery/core/backup/backup_concurrency.dart';

void main() {
  test('returns results in original order', () async {
    final results = await runWithConcurrency<int, int>(
      items: [1, 2, 3, 4, 5],
      concurrency: 3,
      task: (item, index) async {
        await Future<void>.delayed(Duration(milliseconds: item * 10));
        return index * 10 + item;
      },
    );

    expect(results, equals([1, 12, 23, 34, 45]));
  });

  test('never exceeds concurrency limit', () async {
    var inFlight = 0;
    var peak = 0;
    final started = Completer<void>();

    final results = await runWithConcurrency<int, int>(
      items: List<int>.generate(8, (index) => index),
      concurrency: 3,
      task: (item, index) async {
        inFlight++;
        peak = inFlight > peak ? inFlight : peak;
        if (item == 0) {
          started.complete();
        }
        await started.future;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        inFlight--;
        return index;
      },
    );

    expect(results.length, 8);
    expect(peak, lessThanOrEqualTo(3));
  });

  test('shouldCancel stops scheduling new work', () async {
    var startedCount = 0;
    var cancel = false;

    final results = await runWithConcurrency<int, int>(
      items: List<int>.generate(6, (index) => index),
      concurrency: 3,
      shouldCancel: () => cancel,
      task: (item, index) async {
        startedCount++;
        if (startedCount == 2) {
          cancel = true;
        }
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return item;
      },
    );

    expect(startedCount, lessThan(6));
    expect(results.nonNulls.length, startedCount);
  });

  test('empty input returns empty list', () async {
    final results = await runWithConcurrency<int, int>(
      items: const [],
      concurrency: 3,
      task: (item, index) async => item,
    );

    expect(results, isEmpty);
  });
}
