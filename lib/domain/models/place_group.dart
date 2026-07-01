import 'package:social_gallery/domain/models/media_item.dart';

/// A group of media items at a specific country and city/locality.
class PlaceGroup {
  const PlaceGroup({
    required this.countryName,
    required this.locality,
    required this.mediaItems,
  });

  final String countryName;
  final String locality;
  final List<MediaItem> mediaItems;

  int get count => mediaItems.length;

  MediaItem? get coverItem => mediaItems.isEmpty ? null : mediaItems.first;
}

/// Country-level grouping containing city/locality sub-groups.
class CountryPlaceGroup {
  const CountryPlaceGroup({
    required this.countryName,
    required this.cities,
    required this.allMedia,
  });

  final String countryName;
  final List<PlaceGroup> cities;
  final List<MediaItem> allMedia;

  int get count => allMedia.length;

  MediaItem? get coverItem => allMedia.isEmpty ? null : allMedia.first;
}
