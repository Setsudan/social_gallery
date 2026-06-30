/// Timeline zoom level for the gallery grid (pinch changes period).
enum GalleryGroupingPeriod {
  day,
  month,
  year;

  String get label {
    switch (this) {
      case GalleryGroupingPeriod.day:
        return 'Days';
      case GalleryGroupingPeriod.month:
        return 'Months';
      case GalleryGroupingPeriod.year:
        return 'Years';
    }
  }

  GalleryGroupingPeriod zoomIn() {
    switch (this) {
      case GalleryGroupingPeriod.year:
        return GalleryGroupingPeriod.month;
      case GalleryGroupingPeriod.month:
        return GalleryGroupingPeriod.day;
      case GalleryGroupingPeriod.day:
        return GalleryGroupingPeriod.day;
    }
  }

  GalleryGroupingPeriod zoomOut() {
    switch (this) {
      case GalleryGroupingPeriod.day:
        return GalleryGroupingPeriod.month;
      case GalleryGroupingPeriod.month:
        return GalleryGroupingPeriod.year;
      case GalleryGroupingPeriod.year:
        return GalleryGroupingPeriod.year;
    }
  }

  /// Grid columns for gallery thumbnails; fewer columns = larger tiles.
  int crossAxisCountForWidth(double width) {
    switch (this) {
      case GalleryGroupingPeriod.day:
        if (width > 1200) return 4;
        if (width > 800) return 3;
        return 3;
      case GalleryGroupingPeriod.month:
        if (width > 1200) return 6;
        if (width > 800) return 5;
        return 4;
      case GalleryGroupingPeriod.year:
        if (width > 1200) return 10;
        if (width > 800) return 8;
        return 6;
    }
  }
}
