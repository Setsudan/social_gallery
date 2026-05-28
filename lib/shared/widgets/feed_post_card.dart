import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/core/utils/media_hero.dart';
import 'package:social_gallery/domain/models/feed_item.dart';
import 'package:social_gallery/shared/widgets/folder_avatar.dart';
import 'package:social_gallery/shared/widgets/media_thumbnail.dart';
import 'package:social_gallery/shared/widgets/motion/pressable_scale.dart';

class FeedPostCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final media = item.media;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: OneUiSpacing.pageHorizontal,
        vertical: OneUiSpacing.sm,
      ),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OneUiRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PressableScale(
            onTap: onFolderTap,
            child: ListTile(
              leading: FolderAvatar(name: item.folderName),
              title: Text(
                item.folderName,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          AspectRatio(
            aspectRatio: 1,
            child: PressableScale(
              onTap: onMediaTap,
              onLongPress: onFavoriteTap,
              child: MediaThumbnail(
                assetId: media.uri,
                showVideoBadge: media.isVideo,
                heroTag: mediaHeroTag(media.id),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                PressableScale(
                  scale: 0.88,
                  onTap: onFavoriteTap,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      media.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: media.isFavorite ? Colors.red : null,
                    ),
                  ),
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
