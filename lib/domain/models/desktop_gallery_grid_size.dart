/// Thumbnail density for Gallery and Explore grids (compact / comfortable / large).
///
/// Storage key remains `settings_desktop_gallery_grid_size` for compatibility.
/// [standard] is shown in the UI as "Comfortable".
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
