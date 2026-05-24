import 'media_item.dart';

class FolderWithStories {
  const FolderWithStories({
    required this.folderName,
    required this.folderPath,
    required this.newMediaCount,
    required this.latestMedia,
    this.hasUnseenContent = true,
    this.storyLastViewedTime = 0,
  });

  final String folderName;
  final String folderPath;
  final int newMediaCount;
  final List<MediaItem> latestMedia;
  final bool hasUnseenContent;
  final int storyLastViewedTime;
}
