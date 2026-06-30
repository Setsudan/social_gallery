import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/shared/widgets/asset_video_player.dart';
import 'package:social_gallery/shared/widgets/media_thumbnail.dart';

class OrganizeCard extends StatelessWidget {
  const OrganizeCard({
    super.key,
    required this.item,
    this.overlayColor,
    this.playbackActive = false,
  });

  final MediaItem item;
  final Color? overlayColor;
  final bool playbackActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = DateTime.fromMillisecondsSinceEpoch(item.sortDate);
    final dateStr = DateFormat.yMMMd().add_jm().format(date);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (item.isVideo && playbackActive)
            _VideoContent(item: item)
          else
            MediaThumbnail(
              assetId: item.uri,
              fit: BoxFit.cover,
              maxThumbnailEdge: 720,
              showVideoBadge: item.isVideo,
            ),
          if (overlayColor != null)
            ColoredBox(color: overlayColor!),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.75),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dateStr,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.folderName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    if (item.width != null && item.height != null)
                      Text(
                        '${item.width} x ${item.height}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white60,
                        ),
                      ),
                    if (item.cameraModel != null)
                      Text(
                        item.cameraModel!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white60,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoContent extends StatefulWidget {
  const _VideoContent({required this.item});

  final MediaItem item;

  @override
  State<_VideoContent> createState() => _VideoContentState();
}

class _VideoContentState extends State<_VideoContent> {
  AssetEntity? _entity;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (usesFilesystemGallery) return;
    final entity = await AssetEntity.fromId(widget.item.uri);
    if (mounted) setState(() => _entity = entity);
  }

  @override
  Widget build(BuildContext context) {
    if (usesFilesystemGallery) {
      return AssetVideoPlayer(assetPath: widget.item.uri, fit: BoxFit.cover);
    }
    if (_entity == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return AssetVideoPlayer(entity: _entity, fit: BoxFit.cover);
  }
}
