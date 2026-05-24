import 'package:flutter/material.dart';
import 'package:social_gallery/domain/models/feed_item.dart';
import 'package:social_gallery/shared/widgets/folder_avatar.dart';
import 'package:social_gallery/shared/widgets/media_thumbnail.dart';

class FeedPostCard extends StatelessWidget {
  const FeedPostCard({
    super.key,
    required this.item,
    required this.onFolderTap,
    required this.onMediaTap,
    required this.onFavoriteTap,
  });

  final FeedItem item;
  final VoidCallback onFolderTap;
  final VoidCallback onMediaTap;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = item.media;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: FolderAvatar(name: item.folderName),
            title: Text(
              item.folderName,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: onFolderTap,
          ),
          AspectRatio(
            aspectRatio: 1,
            child: GestureDetector(
              onTap: onMediaTap,
              onDoubleTap: onFavoriteTap,
              child: MediaThumbnail(
                assetId: media.uri,
                showVideoBadge: media.isVideo,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    media.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: media.isFavorite ? Colors.red : null,
                  ),
                  onPressed: onFavoriteTap,
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
