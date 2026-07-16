import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:social_gallery/core/media/asset_media_kind.dart';
import 'package:social_gallery/shared/widgets/unsupported_media_placeholder.dart';

/// Central routing for thumbnails, fullscreen, and mime inference.
class AssetMediaLoader {
  const AssetMediaLoader._();

  static const _imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'heic',
    'heif',
    'tif',
    'tiff',
    'dng',
    'cr2',
    'nef',
    'arw',
    'orf',
    'rw2',
  };

  static const _videoExtensions = {
    'mp4',
    'mov',
    'm4v',
    'avi',
    'mkv',
    'webm',
    '3gp',
    'mpeg',
    'mpg',
    'wmv',
    'flv',
  };

  static const _audioExtensions = {
    'mp3',
    'm4a',
    'aac',
    'wav',
    'flac',
    'ogg',
    'opus',
    'wma',
  };

  /// Whether [AssetEntityImageProvider] is safe (image/video native types only).
  static bool canUseAssetImageProvider(AssetEntity entity) {
    return entity.type == AssetType.image || entity.type == AssetType.video;
  }

  static AssetMediaKind classify(AssetEntity entity) {
    switch (entity.type) {
      case AssetType.image:
        return AssetMediaKind.image;
      case AssetType.video:
        return AssetMediaKind.video;
      case AssetType.audio:
        return AssetMediaKind.audio;
      case AssetType.other:
        return _classifyOther(entity);
    }
  }

  static bool isVideo(AssetEntity entity) {
    return classify(entity) == AssetMediaKind.video;
  }

  static bool isImage(AssetEntity entity) {
    return classify(entity) == AssetMediaKind.image;
  }

  static AssetMediaKind _classifyOther(AssetEntity entity) {
    if (entity.isLivePhoto) {
      return AssetMediaKind.image;
    }

    final mime = entity.mimeType?.toLowerCase();
    if (mime != null && mime.isNotEmpty) {
      if (mime.startsWith('video/')) return AssetMediaKind.video;
      if (mime.startsWith('image/')) return AssetMediaKind.image;
      if (mime.startsWith('audio/')) return AssetMediaKind.audio;
    }

    final ext = extensionFromEntity(entity);
    if (ext != null) {
      if (_videoExtensions.contains(ext)) return AssetMediaKind.video;
      if (_imageExtensions.contains(ext)) return AssetMediaKind.image;
      if (_audioExtensions.contains(ext)) return AssetMediaKind.audio;
    }

    if (entity.duration > 0 && entity.width > 0 && entity.height > 0) {
      return AssetMediaKind.video;
    }

    return AssetMediaKind.unsupported;
  }

  static String? extensionFromEntity(AssetEntity entity) {
    final fromTitle = _extensionFromName(entity.title);
    if (fromTitle != null) return fromTitle;

    final mime = entity.mimeType;
    if (mime != null && mime.contains('/')) {
      final subtype = mime.split('/').last.toLowerCase();
      if (subtype.isNotEmpty && subtype != 'octet-stream') {
        return subtype;
      }
    }
    return null;
  }

  static String? _extensionFromName(String? name) {
    if (name == null || name.isEmpty) return null;
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot >= name.length - 1) return null;
    return name.substring(dot + 1).toLowerCase();
  }

  /// Mime for DB sync; prefers platform mime, then extension heuristics.
  static String inferMimeTypeSync(AssetEntity asset) {
    final synced = asset.mimeType;
    if (synced != null && synced.isNotEmpty) {
      return synced;
    }

    switch (classify(asset)) {
      case AssetMediaKind.video:
        return 'video/mp4';
      case AssetMediaKind.image:
        return _imageMimeFromExtension(extensionFromEntity(asset)) ??
            'image/jpeg';
      case AssetMediaKind.audio:
        return 'audio/mpeg';
      case AssetMediaKind.unsupported:
        return 'application/octet-stream';
    }
  }

  static Future<String> inferMimeType(AssetEntity asset) async {
    final synced = asset.mimeType;
    if (synced != null && synced.isNotEmpty) {
      return synced;
    }

    final asyncMime = await asset.mimeTypeAsync;
    if (asyncMime != null && asyncMime.isNotEmpty) {
      return asyncMime;
    }

    switch (classify(asset)) {
      case AssetMediaKind.video:
        return 'video/mp4';
      case AssetMediaKind.image:
        return _imageMimeFromExtension(extensionFromEntity(asset)) ??
            'image/jpeg';
      case AssetMediaKind.audio:
        return 'audio/mpeg';
      case AssetMediaKind.unsupported:
        return 'application/octet-stream';
    }
  }

  static String? _imageMimeFromExtension(String? ext) {
    if (ext == null) return null;
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
      case 'heif':
        return 'image/heif';
      case 'bmp':
        return 'image/bmp';
      case 'tif':
      case 'tiff':
        return 'image/tiff';
      default:
        return 'image/jpeg';
    }
  }

  static Future<File?> resolveDisplayFile(AssetEntity entity) async {
    final file = await entity.file;
    if (file != null && file.existsSync()) {
      return file;
    }
    final origin = await entity.originFile;
    if (origin != null && origin.existsSync()) {
      return origin;
    }
    return null;
  }

  /// Preserves source aspect ratio so [BoxFit.cover] can crop in the layout.
  static int _maxThumbnailEdge(ThumbnailSize size) {
    return size.width > size.height ? size.width : size.height;
  }

  static ThumbnailSize thumbnailSizeForEntity(
    AssetEntity entity, {
    int maxEdge = 800,
  }) {
    final w = entity.width;
    final h = entity.height;
    if (w <= 0 || h <= 0) {
      return const ThumbnailSize.square(800);
    }
    if (w >= h) {
      return ThumbnailSize(maxEdge, (maxEdge * h / w).round().clamp(1, maxEdge));
    }
    return ThumbnailSize((maxEdge * w / h).round().clamp(1, maxEdge), maxEdge);
  }

  /// Grid / card thumbnail: never uses APIs that throw on [AssetType.other].
  static Widget buildThumbnail({
    required AssetEntity entity,
    BoxFit fit = BoxFit.cover,
    ThumbnailSize? thumbnailSize,
  }) {
    final kind = classify(entity);
    final resolvedSize = thumbnailSize ?? thumbnailSizeForEntity(entity);

    if (kind == AssetMediaKind.unsupported || kind == AssetMediaKind.audio) {
      return UnsupportedMediaPlaceholder(kind: kind, entity: entity, fit: fit);
    }

    if (canUseAssetImageProvider(entity)) {
      return SizedBox.expand(
        child: Image(
          image: AssetEntityImageProvider(
            entity,
            isOriginal: false,
            thumbnailSize: resolvedSize,
          ),
          fit: fit,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) =>
              UnsupportedMediaPlaceholder(kind: kind, entity: entity, fit: fit),
        ),
      );
    }

    if (kind == AssetMediaKind.image) {
      return _FileThumbnail(
        entity: entity,
        fit: fit,
        cacheWidth: _maxThumbnailEdge(resolvedSize),
      );
    }

    return UnsupportedMediaPlaceholder(
      kind: AssetMediaKind.video,
      entity: entity,
      fit: fit,
      icon: Icons.videocam_outlined,
    );
  }

  /// Fullscreen still image (not video player).
  static Widget buildFullscreenImage({
    required AssetEntity entity,
    BoxFit fit = BoxFit.contain,
    String? heroTag,
    int? cacheWidth,
  }) {
    final kind = classify(entity);
    if (kind != AssetMediaKind.image) {
      return UnsupportedMediaPlaceholder(
        kind: kind,
        entity: entity,
        fit: fit,
        icon: Icons.broken_image_outlined,
      );
    }

    final edge = cacheWidth ?? 2048;
    final Widget imageChild;
    if (canUseAssetImageProvider(entity)) {
      imageChild = Image(
        image: AssetEntityImageProvider(
          entity,
          isOriginal: false,
          thumbnailSize: ThumbnailSize(edge, edge),
        ),
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => _FileFullscreenImage(
          entity: entity,
          fit: fit,
          cacheWidth: edge,
        ),
      );
    } else {
      imageChild = _FileFullscreenImage(
        entity: entity,
        fit: fit,
        cacheWidth: edge,
      );
    }

    if (heroTag == null) return imageChild;

    return Hero(
      tag: heroTag,
      flightShuttleBuilder:
          (
            flightContext,
            animation,
            flightDirection,
            fromHeroContext,
            toHeroContext,
          ) {
            final shuttleHero = flightDirection == HeroFlightDirection.pop
                ? fromHeroContext.widget as Hero
                : toHeroContext.widget as Hero;
            return SizedBox.expand(
              child: FittedBox(fit: BoxFit.contain, child: shuttleHero.child),
            );
          },
      child: imageChild,
    );
  }
}

class _FileThumbnail extends StatelessWidget {
  const _FileThumbnail({
    required this.entity,
    required this.fit,
    required this.cacheWidth,
  });

  final AssetEntity entity;
  final BoxFit fit;
  final int cacheWidth;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: AssetMediaLoader.resolveDisplayFile(entity),
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file == null) {
          return UnsupportedMediaPlaceholder(
            kind: AssetMediaKind.image,
            entity: entity,
            fit: fit,
          );
        }
        return SizedBox.expand(
          child: Image.file(
            file,
            fit: fit,
            cacheWidth: cacheWidth,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) =>
                UnsupportedMediaPlaceholder(
                  kind: AssetMediaKind.image,
                  entity: entity,
                  fit: fit,
                ),
          ),
        );
      },
    );
  }
}

class _FileFullscreenImage extends StatelessWidget {
  const _FileFullscreenImage({
    required this.entity,
    required this.fit,
    this.cacheWidth,
  });

  final AssetEntity entity;
  final BoxFit fit;
  final int? cacheWidth;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: AssetMediaLoader.resolveDisplayFile(entity),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        final file = snapshot.data;
        if (file == null) {
          return UnsupportedMediaPlaceholder(
            kind: AssetMediaKind.unsupported,
            entity: entity,
            fit: fit,
          );
        }
        return Image.file(
          file,
          fit: fit,
          cacheWidth: cacheWidth,
          gaplessPlayback: true,
        );
      },
    );
  }
}
