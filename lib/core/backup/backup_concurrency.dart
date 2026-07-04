/// Runs [task] over [items] with at most [concurrency] tasks in flight.
///
/// Results are returned in the same order as [items]. Entries are null when
/// [shouldCancel] prevented the task from starting. In-flight tasks still
/// complete when cancellation is requested.
Future<List<R?>> runWithConcurrency<E, R>({
  required List<E> items,
  required int concurrency,
  required Future<R> Function(E item, int index) task,
  bool Function()? shouldCancel,
}) async {
  if (items.isEmpty) return const [];

  final workerCount = concurrency.clamp(1, items.length);
  final results = List<R?>.filled(items.length, null);
  var nextIndex = 0;

  Future<void> worker() async {
    while (true) {
      if (shouldCancel?.call() ?? false) {
        return;
      }

      final index = nextIndex;
      nextIndex++;
      if (index >= items.length) {
        return;
      }

      results[index] = await task(items[index], index);
    }
  }

  await Future.wait(List.generate(workerCount, (_) => worker()));
  return results;
}
