import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/app/router.dart';
import 'package:social_gallery/domain/models/media_item.dart';

/// Max items kept in a swipe session to bound memory after deep scroll.
const mediaViewerMaxSessionItems = 120;

/// Items to swipe through in post detail, set immediately before navigation.
class MediaViewerSession {
  const MediaViewerSession({
    required this.items,
    required this.initialIndex,
  });

  final List<MediaItem> items;
  final int initialIndex;
}

final mediaViewerSessionProvider = StateProvider<MediaViewerSession?>(
  (ref) => null,
);

/// Returns a window of [items] centered on [index], capped at [maxItems].
({List<MediaItem> items, int index}) boundMediaViewerWindow(
  List<MediaItem> items,
  int index, {
  int maxItems = mediaViewerMaxSessionItems,
}) {
  if (items.isEmpty) {
    return (items: items, index: 0);
  }
  final clampedIndex = index.clamp(0, items.length - 1);
  if (items.length <= maxItems) {
    return (items: items, index: clampedIndex);
  }
  final half = maxItems ~/ 2;
  var start = clampedIndex - half;
  if (start < 0) start = 0;
  if (start + maxItems > items.length) {
    start = items.length - maxItems;
  }
  return (
    items: items.sublist(start, start + maxItems),
    index: clampedIndex - start,
  );
}

void openMediaViewer(
  BuildContext context,
  WidgetRef ref, {
  required List<MediaItem> items,
  required MediaItem item,
}) {
  final rawIndex = items.indexWhere((m) => m.id == item.id);
  final window = boundMediaViewerWindow(
    items,
    rawIndex >= 0 ? rawIndex : 0,
  );
  ref.read(mediaViewerSessionProvider.notifier).state = MediaViewerSession(
    items: window.items,
    initialIndex: window.index,
  );
  context.push(
    postDetailLocation(
      item.uri,
      mediaId: item.id,
      favorite: item.isFavorite,
    ),
  );
}
