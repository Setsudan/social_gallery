import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/media/thumbnail_decode.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/shared/media/thumbnail_prefetch.dart';
import 'package:social_gallery/shared/widgets/floating_bottom_nav.dart';
import 'package:social_gallery/shared/widgets/media_backup_badge.dart';
import 'package:social_gallery/shared/widgets/media_grid.dart';
import 'package:social_gallery/shared/widgets/media_thumbnail.dart';
import 'package:social_gallery/shared/widgets/motion/pressable_scale.dart';
import 'package:social_gallery/shared/widgets/motion/selection_chrome.dart';

/// Pinterest-style explore grid: groups of 3 with alternating big-left / 3-up / big-right.
class ExploreMosaicGrid extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final syncingMediaId = usesFilesystemGallery
        ? null
        : ref.watch(desktopBackupProvider.select((s) => s.syncingMediaId));

    final padding = FloatingNavInsets.scrollPadding(
      context,
    ).add(EdgeInsets.all(spacing));
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final contentWidth =
        MediaQuery.sizeOf(context).width - padding.horizontal;
    final smallLogical = (contentWidth - spacing * 2) / 3;
    final bigLogical = smallLogical * 2 + spacing;
    final smallThumbEdge = thumbnailDecodeEdge(
      logicalWidth: smallLogical,
      devicePixelRatio: dpr,
      maxEdge: 256,
    );
    final bigThumbEdge = thumbnailDecodeEdge(
      logicalWidth: bigLogical,
      devicePixelRatio: dpr,
      maxEdge: 384,
    );
    // Prefetch at the larger edge so big tiles stay sharp.
    final prefetchEdge = bigThumbEdge;

    final blockCount = (items.length + 2) ~/ 3;
    final listItemCount = blockCount + (showLoadingFooter ? 1 : 0);
    final assetIds = List<String>.generate(
      items.length,
      (i) => items[i].uri,
      growable: false,
    );

    // Average mosaic block height ~ big tile (covers big+small and 3-up rows).
    final approxBlockExtent = bigLogical + spacing;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.axis != Axis.vertical) return false;
        if (notification is! ScrollUpdateNotification &&
            notification is! ScrollEndNotification) {
          return false;
        }
        ThumbnailPrefetcher.instance.scheduleForGrid(
          metrics: notification.metrics,
          assetIds: assetIds,
          crossAxisCount: 3,
          mainAxisExtent: approxBlockExtent,
          thumbnailEdge: prefetchEdge,
          context: context,
          aheadCount: 48,
        );
        return false;
      },
      child: ListView.builder(
        controller: controller,
        padding: padding,
        cacheExtent: kMediaGridCacheExtent,
        addAutomaticKeepAlives: false,
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

          // Sizes come from MediaQuery above — avoid per-block LayoutBuilder
          // so scroll only lays out fixed geometry.
          switch (blockIndex % 4) {
            case 0:
              return Padding(
                padding: EdgeInsets.only(bottom: spacing),
                child: _MosaicBigBlock(
                  bigOnLeft: true,
                  spacing: spacing,
                  bigSize: bigLogical,
                  smallSize: smallLogical,
                  mediaBig: media0,
                  mediaSmallTop: media1,
                  mediaSmallBottom: media2,
                  onTap: onTap,
                  selectedIds: selectedIds,
                  onLongPress: onLongPress,
                  onSelectToggle: onSelectToggle,
                  syncingMediaId: syncingMediaId,
                  bigThumbEdge: bigThumbEdge,
                  smallThumbEdge: smallThumbEdge,
                ),
              );
            case 3:
              return Padding(
                padding: EdgeInsets.only(bottom: spacing),
                child: _MosaicBigBlock(
                  bigOnLeft: false,
                  spacing: spacing,
                  bigSize: bigLogical,
                  smallSize: smallLogical,
                  mediaBig: media0,
                  mediaSmallTop: media1,
                  mediaSmallBottom: media2,
                  onTap: onTap,
                  selectedIds: selectedIds,
                  onLongPress: onLongPress,
                  onSelectToggle: onSelectToggle,
                  syncingMediaId: syncingMediaId,
                  bigThumbEdge: bigThumbEdge,
                  smallThumbEdge: smallThumbEdge,
                ),
              );
            default:
              return Padding(
                padding: EdgeInsets.only(bottom: spacing),
                child: _MosaicSmallRow(
                  spacing: spacing,
                  cellSize: smallLogical,
                  media0: media0,
                  media1: media1,
                  media2: media2,
                  onTap: onTap,
                  selectedIds: selectedIds,
                  onLongPress: onLongPress,
                  onSelectToggle: onSelectToggle,
                  syncingMediaId: syncingMediaId,
                  thumbEdge: smallThumbEdge,
                ),
              );
          }
        },
      ),
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
    required this.bigThumbEdge,
    required this.smallThumbEdge,
    this.onLongPress,
    this.onSelectToggle,
    this.syncingMediaId,
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
  final int? syncingMediaId;
  final int bigThumbEdge;
  final int smallThumbEdge;

  @override
  Widget build(BuildContext context) {
    final bigTile = _MosaicTile(
      size: bigSize,
      item: mediaBig,
      onTap: onTap,
      selectedIds: selectedIds,
      onLongPress: onLongPress,
      onSelectToggle: onSelectToggle,
      syncingMediaId: syncingMediaId,
      maxThumbnailEdge: bigThumbEdge,
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
          syncingMediaId: syncingMediaId,
          maxThumbnailEdge: smallThumbEdge,
        ),
        SizedBox(height: spacing),
        _MosaicTile(
          size: smallSize,
          item: mediaSmallBottom,
          onTap: onTap,
          selectedIds: selectedIds,
          onLongPress: onLongPress,
          onSelectToggle: onSelectToggle,
          syncingMediaId: syncingMediaId,
          maxThumbnailEdge: smallThumbEdge,
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
    required this.thumbEdge,
    this.onLongPress,
    this.onSelectToggle,
    this.syncingMediaId,
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
  final int? syncingMediaId;
  final int thumbEdge;

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
          syncingMediaId: syncingMediaId,
          maxThumbnailEdge: thumbEdge,
        ),
        SizedBox(width: spacing),
        _MosaicTile(
          size: cellSize,
          item: media1,
          onTap: onTap,
          selectedIds: selectedIds,
          onLongPress: onLongPress,
          onSelectToggle: onSelectToggle,
          syncingMediaId: syncingMediaId,
          maxThumbnailEdge: thumbEdge,
        ),
        SizedBox(width: spacing),
        _MosaicTile(
          size: cellSize,
          item: media2,
          onTap: onTap,
          selectedIds: selectedIds,
          onLongPress: onLongPress,
          onSelectToggle: onSelectToggle,
          syncingMediaId: syncingMediaId,
          maxThumbnailEdge: thumbEdge,
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
    required this.maxThumbnailEdge,
    this.onLongPress,
    this.onSelectToggle,
    this.syncingMediaId,
  });

  final double size;
  final MediaItem? item;
  final void Function(MediaItem item) onTap;
  final Set<int> selectedIds;
  final void Function(MediaItem item)? onLongPress;
  final void Function(MediaItem item)? onSelectToggle;
  final int? syncingMediaId;
  final int maxThumbnailEdge;

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
          animatePress: false,
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
              maxThumbnailEdge: maxThumbnailEdge,
              backupState: visibleBackupState(
                item!,
                syncingMediaId: syncingMediaId,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

