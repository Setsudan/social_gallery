import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/core/utils/media_hero.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/shared/widgets/floating_bottom_nav.dart';
import 'package:social_gallery/shared/widgets/media_thumbnail.dart';
import 'package:social_gallery/shared/widgets/motion/pressable_scale.dart';
import 'package:social_gallery/shared/widgets/motion/selection_chrome.dart';
import 'package:social_gallery/shared/widgets/motion/staggered_entrance.dart';

class MediaGrid extends ConsumerWidget {
  const MediaGrid({
    super.key,
    required this.items,
    required this.onTap,
    this.controller,
    this.crossAxisCount = 3,
    this.locked = false,
    this.selectedIds = const {},
    this.onLongPress,
    this.onSelectToggle,
    this.staggerEntrance = true,
  });

  final List<MediaItem> items;
  final void Function(MediaItem item) onTap;
  final ScrollController? controller;
  final int crossAxisCount;
  final bool locked;
  final Set<int> selectedIds;
  final void Function(MediaItem item)? onLongPress;
  final void Function(MediaItem item)? onSelectToggle;
  final bool staggerEntrance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final padding = FloatingNavInsets.scrollPadding(
      context,
    ).add(const EdgeInsets.all(2));

    final inSelectionMode = selectedIds.isNotEmpty;

    return GridView.builder(
      controller: controller,
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = selectedIds.contains(item.id);

        Widget tile = PressableScale(
          enabled: !locked,
          onTap: locked
              ? null
              : () {
                  if (inSelectionMode && onSelectToggle != null) {
                    onSelectToggle!(item);
                  } else {
                    onTap(item);
                  }
                },
          onLongPress: locked
              ? null
              : () {
                  if (onLongPress != null) {
                    onLongPress!(item);
                  }
                },
          child: MediaSelectionOverlay(
            selected: isSelected,
            inSelectionMode: inSelectionMode,
            child: MediaThumbnail(
              assetId: item.uri,
              showVideoBadge: item.isVideo,
              locked: locked,
              heroTag: mediaHeroTag(item.id),
            ),
          ),
        );

        if (staggerEntrance) {
          tile = StaggeredEntrance(index: index, child: tile);
        }

        return tile;
      },
    );
  }
}
