import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/app/router.dart';
import 'package:social_gallery/domain/models/media_item.dart';

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

void openMediaViewer(
  BuildContext context,
  WidgetRef ref, {
  required List<MediaItem> items,
  required MediaItem item,
}) {
  final index = items.indexWhere((m) => m.id == item.id);
  ref.read(mediaViewerSessionProvider.notifier).state = MediaViewerSession(
    items: items,
    initialIndex: index >= 0 ? index : 0,
  );
  context.push(
    postDetailLocation(
      item.uri,
      mediaId: item.id,
      favorite: item.isFavorite,
    ),
  );
}
