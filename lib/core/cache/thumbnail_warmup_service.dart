import 'dart:io';
import 'dart:ui' as ui;

import 'package:photo_manager/photo_manager.dart';
import 'package:social_gallery/core/media/asset_entity_cache.dart';
import 'package:social_gallery/core/media/asset_media_loader.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';

/// Pre-decodes recent thumbnails so the gallery feels instant on reopen.
class ThumbnailWarmupService {
  static const defaultWarmCount = 48;
  static const _thumbnailEdge = 256;

  Future<void> warmAssetIds(
    Iterable<String> assetIds, {
    int limit = defaultWarmCount,
  }) async {
    final ids = assetIds.take(limit).toList(growable: false);
    if (ids.isEmpty) return;

    if (usesFilesystemGallery) {
      await _warmWindowsFiles(ids);
      return;
    }

    for (final id in ids) {
      try {
        final entity = await AssetEntityCache.resolve(id);
        if (entity == null || !AssetMediaLoader.canUseAssetImageProvider(entity)) {
          continue;
        }
        final size = AssetMediaLoader.thumbnailSizeForEntity(
          entity,
          maxEdge: _thumbnailEdge,
        );
        await entity.thumbnailDataWithSize(size);
      } catch (_) {}
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<void> _warmWindowsFiles(List<String> paths) async {
    for (final path in paths) {
      try {
        final file = File(path);
        if (!file.existsSync()) continue;
        final codec = await ui.instantiateImageCodec(
          await file.readAsBytes(),
          targetWidth: _thumbnailEdge,
        );
        codec.dispose();
      } catch (_) {}
      await Future<void>.delayed(Duration.zero);
    }
  }
}
