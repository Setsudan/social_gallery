/// Thumbnail density for the desktop gallery grid.
enum DesktopGalleryGridSize {
  compact,
  standard,
  large;

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
