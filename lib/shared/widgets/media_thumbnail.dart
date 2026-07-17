import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:social_gallery/core/media/asset_entity_cache.dart';
import 'package:social_gallery/core/media/asset_media_loader.dart';
import 'package:social_gallery/core/media/thumbnail_decode.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';
import 'package:social_gallery/domain/models/backup_state.dart';
import 'package:social_gallery/shared/widgets/media_backup_badge.dart';

class MediaThumbnail extends StatefulWidget {
  const MediaThumbnail({
    super.key,
    required this.assetId,
    this.fit = BoxFit.cover,
    this.showVideoBadge = false,
    this.locked = false,
    this.heroTag,
    this.maxThumbnailEdge,
    this.backupState,
  });

  final String assetId;
  final BoxFit fit;
  final bool showVideoBadge;
  final bool locked;
  final String? heroTag;

  /// Optional ceiling for decode size. When set, still respects layout width
  /// so small cells do not decode oversized bitmaps.
  final int? maxThumbnailEdge;
  final MediaBackupState? backupState;

  @override
  State<MediaThumbnail> createState() => _MediaThumbnailState();
}

class _MediaThumbnailState extends State<MediaThumbnail> {
  Future<AssetEntity?>? _entityFuture;
  AssetEntity? _resolvedEntity;

  @override
  void initState() {
    super.initState();
    _bindAsset(widget.assetId);
  }

  @override
  void didUpdateWidget(MediaThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetId != widget.assetId) {
      _bindAsset(widget.assetId);
    }
  }

  void _bindAsset(String assetId) {
    final peeked = AssetEntityCache.peek(assetId);
    if (peeked != null) {
      _resolvedEntity = peeked;
      _entityFuture = null;
      return;
    }
    _resolvedEntity = null;
    _entityFuture = AssetEntityCache.resolve(assetId);
  }

  List<Widget> _overlayBadges({required bool isVideo}) {
    return [
      if (!usesFilesystemGallery && widget.backupState != null)
        MediaBackupBadge(state: widget.backupState!),
      if (isVideo)
        const Positioned(
          right: 4,
          bottom: 4,
          child: Icon(Icons.videocam, color: Colors.white, size: 18),
        ),
    ];
  }

  int _resolveMaxEdge(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final fromLayout = (!width.isFinite || width <= 0)
        ? 256
        : (width * dpr).ceil();
    final capped = widget.maxThumbnailEdge == null
        ? fromLayout.clamp(96, 512)
        : math.min(fromLayout, widget.maxThumbnailEdge!).clamp(96, 1080);
    return snapThumbnailEdge(capped);
  }

  Widget _buildEntityThumb(AssetEntity entity) {
    final isVideo = widget.showVideoBadge || AssetMediaLoader.isVideo(entity);
    final placeholder =
        Theme.of(context).colorScheme.surfaceContainerHigh;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxEdge = _resolveMaxEdge(constraints);
        final thumbnail = AssetMediaLoader.buildThumbnail(
          entity: entity,
          fit: widget.fit,
          thumbnailSize: AssetMediaLoader.thumbnailSizeForEntity(
            entity,
            maxEdge: maxEdge,
          ),
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            // Stable underlay so decode completion paints over instead of popping.
            ColoredBox(color: placeholder),
            widget.heroTag != null
                ? Hero(tag: widget.heroTag!, child: thumbnail)
                : thumbnail,
            ..._overlayBadges(isVideo: isVideo),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.locked) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.lock)),
      );
    }

    if (usesFilesystemGallery) {
      return _buildWindowsThumbnail(context);
    }

    final syncEntity = _resolvedEntity ?? AssetEntityCache.peek(widget.assetId);
    if (syncEntity != null) {
      return _buildEntityThumb(syncEntity);
    }

    return FutureBuilder<AssetEntity?>(
      future: _entityFuture,
      builder: (context, snapshot) {
        final entity = snapshot.data;
        if (entity == null) {
          return ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            child: snapshot.connectionState == ConnectionState.done
                ? const Center(child: Icon(Icons.broken_image_outlined))
                : null,
          );
        }

        return _buildEntityThumb(entity);
      },
    );
  }

  Widget _buildWindowsThumbnail(BuildContext context) {
    final isWinVideo = widget.assetId.toLowerCase().endsWith('.mp4') ||
        widget.assetId.toLowerCase().endsWith('.mov') ||
        widget.assetId.toLowerCase().endsWith('.mkv') ||
        widget.assetId.toLowerCase().endsWith('.webm') ||
        widget.assetId.toLowerCase().endsWith('.avi');
    final isVideo = widget.showVideoBadge || isWinVideo;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxEdge = _resolveMaxEdge(constraints);
        final Widget thumbnail;
        if (isWinVideo) {
          thumbnail = ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            child: const Center(
              child: Icon(Icons.videocam_outlined, size: 36),
            ),
          );
        } else {
          thumbnail = SizedBox.expand(
            child: Image.file(
              File(widget.assetId),
              fit: widget.fit,
              cacheWidth: maxEdge,
              filterQuality: FilterQuality.low,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) => ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                child: const Center(child: Icon(Icons.broken_image_outlined)),
              ),
            ),
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            widget.heroTag != null
                ? Hero(tag: widget.heroTag!, child: thumbnail)
                : thumbnail,
            ..._overlayBadges(isVideo: isVideo),
          ],
        );
      },
    );
  }
}
