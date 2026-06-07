import 'package:flutter/material.dart';
import 'package:social_gallery/core/utils/media_hero.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/shared/widgets/floating_bottom_nav.dart';
import 'package:social_gallery/shared/widgets/media_thumbnail.dart';
import 'package:social_gallery/shared/widgets/motion/pressable_scale.dart';
import 'package:social_gallery/shared/widgets/motion/selection_chrome.dart';
import 'package:social_gallery/shared/widgets/motion/staggered_entrance.dart';

/// Pinterest-style explore grid: groups of 3 with alternating big-left / 3-up / big-right.
class ExploreMosaicGrid extends StatelessWidget {
  const ExploreMosaicGrid({
    super.key,
    required this.items,
    required this.onTap,
    this.controller,
    this.spacing = 2,
    this.selectedIds = const {},
    this.onLongPress,
    this.onSelectToggle,
    this.showLoadingFooter = false,
  });

  final List<MediaItem> items;
  final void Function(MediaItem item) onTap;
  final ScrollController? controller;
  final double spacing;
  final Set<int> selectedIds;
  final void Function(MediaItem item)? onLongPress;
  final void Function(MediaItem item)? onSelectToggle;
  final bool showLoadingFooter;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final padding = FloatingNavInsets.scrollPadding(
      context,
    ).add(EdgeInsets.all(spacing));
    final blockCount = (items.length + 2) ~/ 3;

    final listItemCount = blockCount + (showLoadingFooter ? 1 : 0);

    return ListView.builder(
      controller: controller,
      padding: padding,
      cacheExtent: 600,
      itemCount: listItemCount,
      itemBuilder: (context, blockIndex) {
        if (blockIndex >= blockCount) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final baseIndex = blockIndex * 3;
        final media0 = items[baseIndex];
        final media1 = baseIndex + 1 < items.length
            ? items[baseIndex + 1]
            : null;
        final media2 = baseIndex + 2 < items.length
            ? items[baseIndex + 2]
            : null;

        return StaggeredEntrance(
          index: blockIndex,
          playOnceKey: 'mosaic_$baseIndex',
          child: Padding(
            padding: EdgeInsets.only(bottom: spacing),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final smallSize = (constraints.maxWidth - spacing * 2) / 3;
                final bigSize = smallSize * 2 + spacing;

                switch (blockIndex % 4) {
                  case 0:
                    return _MosaicBigBlock(
                      bigOnLeft: true,
                      spacing: spacing,
                      bigSize: bigSize,
                      smallSize: smallSize,
                      mediaBig: media0,
                      mediaSmallTop: media1,
                      mediaSmallBottom: media2,
                      onTap: onTap,
                      selectedIds: selectedIds,
                      onLongPress: onLongPress,
                      onSelectToggle: onSelectToggle,
                    );
                  case 3:
                    return _MosaicBigBlock(
                      bigOnLeft: false,
                      spacing: spacing,
                      bigSize: bigSize,
                      smallSize: smallSize,
                      mediaBig: media0,
                      mediaSmallTop: media1,
                      mediaSmallBottom: media2,
                      onTap: onTap,
                      selectedIds: selectedIds,
                      onLongPress: onLongPress,
                      onSelectToggle: onSelectToggle,
                    );
                  default:
                    return _MosaicSmallRow(
                      spacing: spacing,
                      cellSize: smallSize,
                      media0: media0,
                      media1: media1,
                      media2: media2,
                      onTap: onTap,
                      selectedIds: selectedIds,
                      onLongPress: onLongPress,
                      onSelectToggle: onSelectToggle,
                    );
                }
              },
            ),
          ),
        );
      },
    );
  }
}

class _MosaicBigBlock extends StatelessWidget {
  const _MosaicBigBlock({
    required this.bigOnLeft,
    required this.spacing,
    required this.bigSize,
    required this.smallSize,
    required this.mediaBig,
    required this.mediaSmallTop,
    required this.mediaSmallBottom,
    required this.onTap,
    required this.selectedIds,
    this.onLongPress,
    this.onSelectToggle,
  });

  final bool bigOnLeft;
  final double spacing;
  final double bigSize;
  final double smallSize;
  final MediaItem mediaBig;
  final MediaItem? mediaSmallTop;
  final MediaItem? mediaSmallBottom;
  final void Function(MediaItem item) onTap;
  final Set<int> selectedIds;
  final void Function(MediaItem item)? onLongPress;
  final void Function(MediaItem item)? onSelectToggle;

  @override
  Widget build(BuildContext context) {
    final bigTile = _MosaicTile(
      size: bigSize,
      item: mediaBig,
      onTap: onTap,
      selectedIds: selectedIds,
      onLongPress: onLongPress,
      onSelectToggle: onSelectToggle,
    );
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MosaicTile(
          size: smallSize,
          item: mediaSmallTop,
          onTap: onTap,
          selectedIds: selectedIds,
          onLongPress: onLongPress,
          onSelectToggle: onSelectToggle,
        ),
        SizedBox(height: spacing),
        _MosaicTile(
          size: smallSize,
          item: mediaSmallBottom,
          onTap: onTap,
          selectedIds: selectedIds,
          onLongPress: onLongPress,
          onSelectToggle: onSelectToggle,
        ),
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (bigOnLeft) ...[
          bigTile,
          SizedBox(width: spacing),
          column,
        ] else ...[
          column,
          SizedBox(width: spacing),
          bigTile,
        ],
      ],
    );
  }
}

class _MosaicSmallRow extends StatelessWidget {
  const _MosaicSmallRow({
    required this.spacing,
    required this.cellSize,
    required this.media0,
    required this.media1,
    required this.media2,
    required this.onTap,
    required this.selectedIds,
    this.onLongPress,
    this.onSelectToggle,
  });

  final double spacing;
  final double cellSize;
  final MediaItem media0;
  final MediaItem? media1;
  final MediaItem? media2;
  final void Function(MediaItem item) onTap;
  final Set<int> selectedIds;
  final void Function(MediaItem item)? onLongPress;
  final void Function(MediaItem item)? onSelectToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MosaicTile(
          size: cellSize,
          item: media0,
          onTap: onTap,
          selectedIds: selectedIds,
          onLongPress: onLongPress,
          onSelectToggle: onSelectToggle,
        ),
        SizedBox(width: spacing),
        _MosaicTile(
          size: cellSize,
          item: media1,
          onTap: onTap,
          selectedIds: selectedIds,
          onLongPress: onLongPress,
          onSelectToggle: onSelectToggle,
        ),
        SizedBox(width: spacing),
        _MosaicTile(
          size: cellSize,
          item: media2,
          onTap: onTap,
          selectedIds: selectedIds,
          onLongPress: onLongPress,
          onSelectToggle: onSelectToggle,
        ),
      ],
    );
  }
}

class _MosaicTile extends StatelessWidget {
  const _MosaicTile({
    required this.size,
    required this.item,
    required this.onTap,
    required this.selectedIds,
    this.onLongPress,
    this.onSelectToggle,
  });

  final double size;
  final MediaItem? item;
  final void Function(MediaItem item) onTap;
  final Set<int> selectedIds;
  final void Function(MediaItem item)? onLongPress;
  final void Function(MediaItem item)? onSelectToggle;

  @override
  Widget build(BuildContext context) {
    if (item == null) {
      return SizedBox(width: size, height: size);
    }

    final isSelected = selectedIds.contains(item!.id);
    final inSelectionMode = selectedIds.isNotEmpty;

    return SizedBox(
      width: size,
      height: size,
      child: RepaintBoundary(
        child: PressableScale(
          onTap: () {
            if (inSelectionMode && onSelectToggle != null) {
              onSelectToggle!(item!);
            } else {
              onTap(item!);
            }
          },
          onLongPress: () {
            if (onLongPress != null) {
              onLongPress!(item!);
            }
          },
          child: MediaSelectionOverlay(
            selected: isSelected,
            inSelectionMode: inSelectionMode,
            child: MediaThumbnail(
              assetId: item!.uri,
              showVideoBadge: item!.isVideo,
              heroTag: mediaHeroTag(item!.id),
            ),
          ),
        ),
      ),
    );
  }
}
