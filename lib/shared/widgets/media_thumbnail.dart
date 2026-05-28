import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:social_gallery/core/media/asset_media_loader.dart';

class MediaThumbnail extends StatelessWidget {
  const MediaThumbnail({
    super.key,
    required this.assetId,
    this.fit = BoxFit.cover,
    this.showVideoBadge = false,
    this.locked = false,
    this.heroTag,
  });

  final String assetId;
  final BoxFit fit;
  final bool showVideoBadge;
  final bool locked;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    if (locked) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.lock)),
      );
    }

    return FutureBuilder<AssetEntity?>(
      future: AssetEntity.fromId(assetId),
      builder: (context, snapshot) {
        final entity = snapshot.data;
        if (entity == null) {
          return ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            child: const Center(child: Icon(Icons.broken_image_outlined)),
          );
        }

        final isVideo = showVideoBadge || AssetMediaLoader.isVideo(entity);
        final thumbnail = AssetMediaLoader.buildThumbnail(
          entity: entity,
          fit: fit,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            heroTag != null ? Hero(tag: heroTag!, child: thumbnail) : thumbnail,
            if (isVideo)
              const Positioned(
                right: 4,
                bottom: 4,
                child: Icon(Icons.videocam, color: Colors.white, size: 18),
              ),
          ],
        );
      },
    );
  }
}
