typedef GallerySyncProgressCallback = void Function(GallerySyncProgress progress);

class GallerySyncProgress {
  const GallerySyncProgress({
    required this.phase,
    required this.detail,
    this.processed = 0,
    this.total = 0,
  });

  final String phase;
  final String detail;
  final int processed;
  final int total;

  double? get fraction => total > 0 ? processed / total : null;
}
