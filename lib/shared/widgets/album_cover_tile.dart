import 'dart:io';

import 'package:flutter/material.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/shared/widgets/media_thumbnail.dart';
import 'package:social_gallery/shared/widgets/motion/pressable_scale.dart';

/// Session cache so album grids do not `stat` the same cover on every rebuild
/// while scrolling. Only local filesystem paths are checked; photo-manager
/// asset ids are never treated as files.
const int _kAlbumCoverExistsCacheLimit = 512;
final Map<String, bool> _albumCoverExistsCache = <String, bool>{};

@visibleForTesting
void debugResetAlbumCoverExistsCache() {
  _albumCoverExistsCache.clear();
}

String? albumCoverLocalFilePath(String uri) {
  final trimmed = uri.trim();
  if (trimmed.isEmpty) return null;

  final path = trimmed.startsWith('file://')
      ? Uri.parse(trimmed).toFilePath()
      : trimmed;
  final looksLikeFilePath =
      path.startsWith('/') || (path.length > 2 && path[1] == ':');
  if (!looksLikeFilePath) return null;
  return path;
}

bool albumCoverUriIsLocalFile(String uri) {
  final cached = _albumCoverExistsCache[uri];
  if (cached != null) return cached;

  final path = albumCoverLocalFilePath(uri);
  final exists = path != null && File(path).existsSync();
  if (_albumCoverExistsCache.length >= _kAlbumCoverExistsCacheLimit) {
    _albumCoverExistsCache.remove(_albumCoverExistsCache.keys.first);
  }
  _albumCoverExistsCache[uri] = exists;
  return exists;
}

class AlbumCoverTile extends StatelessWidget {
  const AlbumCoverTile({
    super.key,
    required this.title,
    required this.onTap,
    this.coverUri,
    this.locked = false,
    this.itemCount,
  });

  final String title;
  final String? coverUri;
  final bool locked;
  final int? itemCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(OneUiRadii.card),
      child: Stack(
        fit: StackFit.expand,
        children: [
          PressableScale(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildCover(context),
                if (locked)
                  ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.72,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.lock,
                        size: 32,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: AlbumCoverScrim(title: title, itemCount: itemCount),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCover(BuildContext context) {
    final cover = coverUri?.trim();
    if (cover != null && cover.isNotEmpty && !locked) {
      final localPath = albumCoverLocalFilePath(cover);
      if (localPath != null && albumCoverUriIsLocalFile(cover)) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final cacheWidth = (200 * dpr).ceil().clamp(96, 800);
        return SizedBox.expand(
          child: Image.file(
            File(localPath),
            fit: BoxFit.cover,
            cacheWidth: cacheWidth,
            filterQuality: FilterQuality.low,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) =>
                MediaThumbnail(assetId: cover),
          ),
        );
      }

      // Photo-manager asset ids (and any non-file URI) must use MediaThumbnail.
      // Never call File.existsSync on those — it is sync IO and can false-cache.
      return SizedBox.expand(child: MediaThumbnail(assetId: cover));
    }

    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Center(
        child: Icon(
          Icons.photo_album_outlined,
          size: 40,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Title strip for an album cover.
///
/// A static gradient, not a [BackdropFilter]. Blurring the pixels behind every
/// visible cover forces a saveLayer per tile and makes the albums grid jank.
class AlbumCoverScrim extends StatelessWidget {
  const AlbumCoverScrim({super.key, required this.title, this.itemCount});

  final String title;
  final int? itemCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FractionallySizedBox(
      heightFactor: 0.44,
      widthFactor: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            stops: const [0.0, 0.55, 1.0],
            colors: [
              Colors.black.withValues(alpha: 0.72),
              Colors.black.withValues(alpha: 0.3),
              Colors.transparent,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                    shadows: const [
                      Shadow(blurRadius: 6, color: Color(0x66000000)),
                    ],
                  ),
                ),
              ),
              if (itemCount != null) ...[
                const SizedBox(height: 2),
                Text(
                  '$itemCount',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                    height: 1.0,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
