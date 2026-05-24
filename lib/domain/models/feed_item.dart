import 'media_item.dart';

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
