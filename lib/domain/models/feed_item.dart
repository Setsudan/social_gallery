import 'media_item.dart';

/// One home-feed row: media plus its source folder for the post header.
class FeedItem {
  const FeedItem({
    required this.folderName,
    required this.folderPath,
    required this.media,
  });

  final String folderName;
  final String folderPath;
  final MediaItem media;
}
