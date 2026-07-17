import 'dart:async';
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:social_gallery/core/media/asset_entity_cache.dart';
import 'package:social_gallery/core/media/asset_media_loader.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';

/// Prefetches upcoming grid/feed thumbnails without blocking the UI isolate.
///
/// Resolves [AssetEntity]s into [AssetEntityCache] and warms OS / Flutter
/// image caches so tiles that enter the viewport soon can paint immediately.
class ThumbnailPrefetcher {
  ThumbnailPrefetcher._();

  static final ThumbnailPrefetcher instance = ThumbnailPrefetcher._();

  static const int defaultAheadCount = 36;
  static const int defaultBehindCount = 12;
  static const Duration _throttle = Duration(milliseconds: 80);
  static const int _warmedCap = 512;

  bool _running = false;
  Timer? _throttleTimer;
  List<String> _pendingIds = const [];
  int _pendingEdge = 256;
  BuildContext? _pendingContext;
  int _lastFirstVisible = 0;
  final Set<String> _warmed = {};
  final List<String> _warmedOrder = [];

  /// Warm a trailing window of asset ids (e.g. right after pagination).
  void warm(
    Iterable<String> assetIds, {
    int limit = defaultAheadCount,
    int thumbnailEdge = 256,
    BuildContext? context,
  }) {
    final ids = assetIds.take(limit).toList(growable: false);
    if (ids.isEmpty) return;
    _enqueue(ids, thumbnailEdge: thumbnailEdge, context: context);
  }

  /// Throttled scroll-driven prefetch from an estimated first-visible index.
  ///
  /// Prefetches a window ahead of the viewport, plus a smaller behind window
  /// when scrolling upward so reverse flings hit warm cache.
  void scheduleFromScroll({
    required List<String> assetIds,
    required int firstVisibleIndex,
    required int thumbnailEdge,
    BuildContext? context,
    int aheadCount = defaultAheadCount,
    int behindCount = defaultBehindCount,
  }) {
    if (assetIds.isEmpty) return;
    final scrollingUp = firstVisibleIndex < _lastFirstVisible;
    _lastFirstVisible = firstVisibleIndex;

    final effectiveBehind = scrollingUp ? behindCount : behindCount ~/ 2;
    final start =
        (firstVisibleIndex - effectiveBehind).clamp(0, assetIds.length);
    final end =
        (firstVisibleIndex + aheadCount).clamp(0, assetIds.length);
    if (start >= end) return;
    final slice = assetIds.sublist(start, end);
    _throttleTimer?.cancel();
    _throttleTimer = Timer(_throttle, () {
      _enqueue(slice, thumbnailEdge: thumbnailEdge, context: context);
    });
  }

  /// Grid helper: estimate first visible index from scroll pixels.
  void scheduleForGrid({
    required ScrollMetrics metrics,
    required List<String> assetIds,
    required int crossAxisCount,
    required double mainAxisExtent,
    required int thumbnailEdge,
    BuildContext? context,
    int aheadCount = defaultAheadCount,
    int behindCount = defaultBehindCount,
  }) {
    if (mainAxisExtent <= 0 || crossAxisCount <= 0) return;
    final firstRow = (metrics.pixels / mainAxisExtent).floor().clamp(0, 1 << 20);
    final firstIndex = firstRow * crossAxisCount;
    scheduleFromScroll(
      assetIds: assetIds,
      firstVisibleIndex: firstIndex,
      thumbnailEdge: thumbnailEdge,
      context: context,
      aheadCount: aheadCount,
      behindCount: behindCount,
    );
  }

  void _enqueue(
    List<String> ids, {
    required int thumbnailEdge,
    BuildContext? context,
  }) {
    // Skip no-op updates that would only restart the same window.
    if (_sameWindow(ids, thumbnailEdge)) return;

    _pendingIds = ids;
    _pendingEdge = thumbnailEdge;
    _pendingContext = context;
    if (!_running) {
      unawaited(_pump());
    }
  }

  bool _sameWindow(List<String> ids, int edge) {
    if (edge != _pendingEdge) return false;
    if (ids.length != _pendingIds.length) return false;
    if (ids.isEmpty) return true;
    if (ids.first != _pendingIds.first) return false;
    if (ids.last != _pendingIds.last) return false;
    return true;
  }

  Future<void> _pump() async {
    if (_running) return;
    _running = true;
    try {
      while (_pendingIds.isNotEmpty) {
        final ids = _pendingIds;
        final edge = _pendingEdge;
        final context = _pendingContext;
        // Claim this batch so newer scroll windows can queue without canceling
        // the item currently being warmed.
        _pendingIds = const [];

        for (var i = 0; i < ids.length; i++) {
          // Newer window arrived — finish current item, then switch.
          if (_pendingIds.isNotEmpty) break;

          final id = ids[i];
          final key = '$id@$edge';
          if (_warmed.contains(key)) continue;

          try {
            await _warmOne(id, edge: edge, context: context);
            _markWarmed(key);
          } catch (_) {}

          // Yield every other item so input stays responsive.
          if (i.isOdd) {
            await Future<void>.delayed(Duration.zero);
          }
        }
      }
    } finally {
      _running = false;
      if (_pendingIds.isNotEmpty) {
        unawaited(_pump());
      }
    }
  }

  void _markWarmed(String key) {
    if (_warmed.add(key)) {
      _warmedOrder.add(key);
      while (_warmedOrder.length > _warmedCap) {
        final oldest = _warmedOrder.removeAt(0);
        _warmed.remove(oldest);
      }
    }
  }

  Future<void> _warmOne(
    String assetId, {
    required int edge,
    BuildContext? context,
  }) async {
    if (usesFilesystemGallery) {
      final file = File(assetId);
      if (!file.existsSync()) return;
      final lower = assetId.toLowerCase();
      if (lower.endsWith('.mp4') ||
          lower.endsWith('.mov') ||
          lower.endsWith('.mkv') ||
          lower.endsWith('.webm') ||
          lower.endsWith('.avi')) {
        return;
      }
      final provider = ResizeImage.resizeIfNeeded(
        edge,
        null,
        FileImage(file),
      );
      if (context != null && context.mounted) {
        await precacheImage(provider, context);
      } else {
        final stream = provider.resolve(ImageConfiguration.empty);
        final completer = Completer<void>();
        late ImageStreamListener listener;
        listener = ImageStreamListener(
          (image, synchronousCall) {
            stream.removeListener(listener);
            completer.complete();
          },
          onError: (exception, stackTrace) {
            stream.removeListener(listener);
            completer.complete();
          },
        );
        stream.addListener(listener);
        await completer.future;
      }
      return;
    }

    final entity = await AssetEntityCache.resolve(assetId);
    if (entity == null) return;
    if (!AssetMediaLoader.canUseAssetImageProvider(entity)) {
      return;
    }

    final size = AssetMediaLoader.thumbnailSizeForEntity(
      entity,
      maxEdge: edge,
    );
    final provider = AssetEntityImageProvider(
      entity,
      isOriginal: false,
      thumbnailSize: size,
    );
    if (context != null && context.mounted) {
      await precacheImage(provider, context);
    } else {
      // Touch OS thumbnail cache even without a BuildContext.
      await entity.thumbnailDataWithSize(size);
    }
  }

  void dispose() {
    _throttleTimer?.cancel();
    _pendingIds = const [];
    _warmed.clear();
    _warmedOrder.clear();
  }
}
