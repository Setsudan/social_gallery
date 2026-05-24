import 'package:flutter/material.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/shared/widgets/floating_bottom_nav.dart';
import 'package:social_gallery/shared/widgets/media_thumbnail.dart';

class MediaGrid extends StatelessWidget {
  const MediaGrid({
    super.key,
    required this.items,
    required this.onTap,
    this.crossAxisCount = 3,
    this.locked = false,
  });

  final List<MediaItem> items;
  final void Function(MediaItem item) onTap;
  final int crossAxisCount;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final padding = FloatingNavInsets.scrollPadding(context).add(
      const EdgeInsets.all(2),
    );

    return GridView.builder(
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: locked ? null : () => onTap(item),
          child: MediaThumbnail(
            assetId: item.uri,
            showVideoBadge: item.isVideo,
            locked: locked,
          ),
        );
      },
    );
  }
}
