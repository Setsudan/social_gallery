import 'package:flutter/material.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/domain/models/folder_with_stories.dart';
import 'package:social_gallery/shared/widgets/media_thumbnail.dart';

/// Avatar (64) + gap (4) + label (~14) + vertical list padding (12).
const double kStoriesRowHeight = 98;

class StoriesRow extends StatelessWidget {
  const StoriesRow({
    super.key,
    required this.folders,
    required this.onFolderTap,
    required this.onCameraTap,
  });

  final List<FolderWithStories> folders;
  final void Function(String folderPath) onFolderTap;
  final VoidCallback onCameraTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kStoriesRowHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: OneUiSpacing.pageHorizontal,
          vertical: 6,
        ),
        itemCount: folders.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _CameraStoryItem(onTap: onCameraTap);
          }
          final folder = folders[index - 1];
          final cover = folder.latestMedia.first;
          return _StoryItem(
            folderName: folder.folderName,
            assetId: cover.uri,
            hasNewContent: folder.hasUnseenContent,
            onTap: () => onFolderTap(folder.folderPath),
          );
        },
      ),
    );
  }
}

class _StoryBubbleLabel extends StatelessWidget {
  const _StoryBubbleLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 14,
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _CameraStoryItem extends StatelessWidget {
  const _CameraStoryItem({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primaryContainer,
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt_outlined,
                      size: 28,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary,
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.add,
                        size: 14,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const _StoryBubbleLabel(text: 'Camera'),
          ],
        ),
      ),
    );
  }
}

class _StoryItem extends StatelessWidget {
  const _StoryItem({
    required this.folderName,
    required this.assetId,
    required this.hasNewContent,
    required this.onTap,
  });

  final String folderName;
  final String assetId;
  final bool hasNewContent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: hasNewContent ? 1 : 0.55,
        child: SizedBox(
          width: 72,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: hasNewContent
                      ? LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.tertiary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  border: hasNewContent
                      ? null
                      : Border.all(
                          color: theme.colorScheme.outlineVariant,
                          width: 1,
                        ),
                ),
                child: ClipOval(child: MediaThumbnail(assetId: assetId)),
              ),
              const SizedBox(height: 4),
              _StoryBubbleLabel(text: folderName),
            ],
          ),
        ),
      ),
    );
  }
}
