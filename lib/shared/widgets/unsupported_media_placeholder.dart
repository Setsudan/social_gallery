import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:social_gallery/core/media/asset_media_kind.dart';
import 'package:social_gallery/core/media/asset_media_loader.dart';

/// Fallback tile / fullscreen content when thumbnails or decoders are unavailable.
class UnsupportedMediaPlaceholder extends StatelessWidget {
  const UnsupportedMediaPlaceholder({
    super.key,
    required this.kind,
    required this.entity,
    this.fit = BoxFit.cover,
    this.icon,
  });

  final AssetMediaKind kind;
  final AssetEntity entity;
  final BoxFit fit;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = _labelForKind(kind, entity);

    return ColoredBox(
      color: scheme.surfaceContainerHigh,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon ?? _defaultIcon(kind),
                size: 32,
                color: scheme.onSurfaceVariant,
              ),
              if (label.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static IconData _defaultIcon(AssetMediaKind kind) {
    switch (kind) {
      case AssetMediaKind.video:
        return Icons.videocam_outlined;
      case AssetMediaKind.audio:
        return Icons.audiotrack_outlined;
      case AssetMediaKind.image:
        return Icons.image_outlined;
      case AssetMediaKind.unsupported:
        return Icons.insert_drive_file_outlined;
    }
  }

  static String _labelForKind(AssetMediaKind kind, AssetEntity entity) {
    final ext = AssetMediaLoader.extensionFromEntity(entity);
    if (ext != null && ext.isNotEmpty) {
      return ext.toUpperCase();
    }
    switch (kind) {
      case AssetMediaKind.video:
        return 'Video';
      case AssetMediaKind.audio:
        return 'Audio';
      case AssetMediaKind.image:
        return 'Image';
      case AssetMediaKind.unsupported:
        return 'File';
    }
  }
}
