import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:social_gallery/core/media/asset_entity_cache.dart';
import 'package:social_gallery/core/media/asset_media_loader.dart';
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
  final int? maxThumbnailEdge;
  final MediaBackupState? backupState;

  @override
  State<MediaThumbnail> createState() => _MediaThumbnailState();
}

class _MediaThumbnailState extends State<MediaThumbnail> {
  late Future<AssetEntity?> _entityFuture;

  @override
  void initState() {
    super.initState();
    _entityFuture = AssetEntityCache.resolve(widget.assetId);
  }

  @override
  void didUpdateWidget(MediaThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetId != widget.assetId) {
      _entityFuture = AssetEntityCache.resolve(widget.assetId);
    }
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
    if (widget.maxThumbnailEdge != null) {
      return widget.maxThumbnailEdge!;
    }
    final width = constraints.maxWidth;
    if (!width.isFinite || width <= 0) {
      return 320;
    }
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return (width * dpr).ceil().clamp(96, 1200);
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

        final isVideo = widget.showVideoBadge || AssetMediaLoader.isVideo(entity);

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
                widget.heroTag != null
                    ? Hero(tag: widget.heroTag!, child: thumbnail)
                    : thumbnail,
                ..._overlayBadges(isVideo: isVideo),
              ],
            );
          },
        );
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
        final thumbnail = SizedBox.expand(
          child: Image.file(
            File(widget.assetId),
            fit: widget.fit,
            cacheWidth: maxEdge,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) => ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              child: const Center(child: Icon(Icons.broken_image_outlined)),
            ),
          ),
        );

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
