import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class MediaThumbnail extends StatelessWidget {
  const MediaThumbnail({
    super.key,
    required this.assetId,
    this.fit = BoxFit.cover,
    this.showVideoBadge = false,
    this.locked = false,
  });

  final String assetId;
  final BoxFit fit;
  final bool showVideoBadge;
  final bool locked;

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

        return Stack(
          fit: StackFit.expand,
          children: [
            Image(
              image: AssetEntityImageProvider(
                entity,
                isOriginal: false,
                thumbnailSize: const ThumbnailSize.square(300),
              ),
              fit: fit,
            ),
            if (showVideoBadge)
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
