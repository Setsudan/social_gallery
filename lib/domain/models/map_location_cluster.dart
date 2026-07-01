import 'package:social_gallery/domain/models/media_item.dart';

/// A map pin representing one or more geotagged media items at a coordinate.
class MapLocationCluster {
  const MapLocationCluster({
    required this.latitude,
    required this.longitude,
    required this.mediaItems,
  });

  final double latitude;
  final double longitude;
  final List<MediaItem> mediaItems;

  int get count => mediaItems.length;
}
