/// Returns true when a duplicate-scan progress notification should be emitted.
bool shouldEmitDuplicateScanProgressNotification(int scanned, int total) {
  if (total <= 0) {
    return scanned == 0;
  }
  if (scanned <= 0 || scanned >= total) {
    return true;
  }

  final step = (total / 20).ceil().clamp(1, total);
  return scanned % step == 0;
}
