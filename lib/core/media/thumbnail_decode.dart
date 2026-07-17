/// Discrete decode sizes so grid tiles share ImageCache / OS thumb entries.
const List<int> kThumbnailEdgeBuckets = [
  96,
  128,
  160,
  192,
  256,
  320,
  384,
  512,
  720,
  1080,
];

/// Snaps [edge] up to the next bucket (or the last bucket if larger).
int snapThumbnailEdge(int edge) {
  if (edge <= kThumbnailEdgeBuckets.first) {
    return kThumbnailEdgeBuckets.first;
  }
  for (final bucket in kThumbnailEdgeBuckets) {
    if (edge <= bucket) return bucket;
  }
  return kThumbnailEdgeBuckets.last;
}

/// Pixel edge for decoding a square-ish thumb shown at [logicalWidth].
int thumbnailDecodeEdge({
  required double logicalWidth,
  required double devicePixelRatio,
  int minEdge = 96,
  int maxEdge = 384,
}) {
  if (!logicalWidth.isFinite || logicalWidth <= 0) {
    return snapThumbnailEdge(minEdge.clamp(minEdge, maxEdge));
  }
  final raw = (logicalWidth * devicePixelRatio).ceil();
  return snapThumbnailEdge(raw.clamp(minEdge, maxEdge));
}
