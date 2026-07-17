import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/layout/responsive_grid.dart';
import 'package:social_gallery/core/media/thumbnail_decode.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/shared/media/thumbnail_prefetch.dart';
import 'package:social_gallery/shared/widgets/floating_bottom_nav.dart';
import 'package:social_gallery/shared/widgets/media_backup_badge.dart';
import 'package:social_gallery/shared/widgets/media_thumbnail.dart';
import 'package:social_gallery/shared/widgets/motion/pressable_scale.dart';
import 'package:social_gallery/shared/widgets/motion/selection_chrome.dart';
import 'package:social_gallery/shared/widgets/motion/staggered_entrance.dart';

/// Look-ahead for grid builders (~1.5 screens of tiles).
const double kMediaGridCacheExtent = 900;

/// Responsive thumbnail grid with optional selection mode and staggered entrance.
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
    this.staggerEntrance = false,
    this.isLoadingMore = false,
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
  final bool isLoadingMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final padding = FloatingNavInsets.scrollPadding(
      context,
    ).add(const EdgeInsets.all(2));

    final inSelectionMode = selectedIds.isNotEmpty;
    final syncingMediaId = usesFilesystemGallery
        ? null
        : ref.watch(desktopBackupProvider.select((s) => s.syncingMediaId));

    final mediaSize = MediaQuery.sizeOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final columns = crossAxisCount == 3
        ? gridCrossAxisCountForWidth(mediaSize.width)
        : crossAxisCount;
    final cellLogical =
        (mediaSize.width - padding.horizontal - (columns - 1) * 2) / columns;
    final thumbEdge = thumbnailDecodeEdge(
      logicalWidth: cellLogical,
      devicePixelRatio: dpr,
      maxEdge: 320,
    );

    final assetIds = List<String>.generate(
      items.length,
      (i) => items[i].uri,
      growable: false,
    );

    final footerCount = isLoadingMore ? 1 : 0;

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
          crossAxisCount: columns,
          mainAxisExtent: cellLogical + 2,
          thumbnailEdge: thumbEdge,
          context: context,
        );
        return false;
      },
      child: GridView.builder(
        controller: controller,
        padding: padding,
        cacheExtent: kMediaGridCacheExtent,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: items.length + footerCount,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        findChildIndexCallback: (key) {
          if (key is! ValueKey<int>) return null;
          final id = key.value;
          for (var i = 0; i < items.length; i++) {
            if (items[i].id == id) return i;
          }
          return null;
        },
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          final item = items[index];
          final isSelected = selectedIds.contains(item.id);

          Widget tile = PressableScale(
            enabled: !locked,
            animatePress: false,
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
                maxThumbnailEdge: thumbEdge,
                backupState: visibleBackupState(
                  item,
                  syncingMediaId: syncingMediaId,
                ),
              ),
            ),
          );

          if (staggerEntrance) {
            tile = StaggeredEntrance(
              index: index,
              playOnceKey: 'grid_${item.id}',
              child: tile,
            );
          }

          return RepaintBoundary(
            key: ValueKey(item.id),
            child: tile,
          );
        },
      ),
    );
  }
}
