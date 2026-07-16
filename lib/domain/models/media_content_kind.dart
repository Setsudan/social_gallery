/// Persisted media classification for search and Discover browse.
enum MediaContentKind {
  unknown(0),
  photo(1),
  screenshot(2),
  document(3);

  const MediaContentKind(this.value);

  final int value;

  static MediaContentKind fromValue(int value) {
    return MediaContentKind.values.firstWhere(
      (k) => k.value == value,
      orElse: () => MediaContentKind.unknown,
    );
  }
}

/// Explore / Gallery search filter for media kind (broader than stored kind).
enum ExploreContentFilter {
  all,
  screenshot,
  document,
  image,
  video,
}
