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
    required this.onShareTap,
  });

  final FeedItem item;
  final VoidCallback onFolderTap;
  final VoidCallback onMediaTap;
  final VoidCallback onFavoriteTap;
  final VoidCallback onShareTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final media = item.media;
    final borderSide = BorderSide(color: theme.dividerColor);

    return Padding(
      padding: const EdgeInsets.only(bottom: OneUiSpacing.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border(top: borderSide)),
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
              onDoubleTap: onFavoriteTap,
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
                PressableScale(
                  scale: 0.88,
                  onTap: onShareTap,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.share_outlined,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }
}
