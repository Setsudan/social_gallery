/// Thumbnail density for the desktop gallery grid.
enum DesktopGalleryGridSize {
  compact,
  standard,
  large;

  String get label => switch (this) {
    compact => 'Compact',
    standard => 'Standard',
    large => 'Large',
  };

  String get subtitle => switch (this) {
    compact => 'Smaller thumbnails, more columns',
    standard => 'Balanced layout',
    large => 'Bigger thumbnails, fewer columns',
  };

  int get columnDelta => switch (this) {
    compact => 3,
    standard => 0,
    large => -2,
  };

  String get storageValue => name;

  static DesktopGalleryGridSize fromStorage(String? value) {
    return switch (value) {
      'compact' => compact,
      'large' => large,
      _ => standard,
    };
  }

  int adjustColumnCount(int baseColumns) {
    return (baseColumns + columnDelta).clamp(2, 20);
  }
}
