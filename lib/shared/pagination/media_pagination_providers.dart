import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers/data_providers.dart';
import 'package:social_gallery/core/media/asset_entity_cache.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';
import 'package:social_gallery/data/repositories/media_repository.dart';
import 'package:social_gallery/domain/models/feed_item.dart';
import 'package:social_gallery/domain/models/explore_search_query.dart';
import 'package:social_gallery/domain/models/media_content_kind.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/shared/media/thumbnail_prefetch.dart';
import 'package:social_gallery/shared/pagination/pagination_controller.dart';

export 'pagination_controller.dart';

typedef PaginatedMediaWarmup =
    void Function(Iterable<String> uris, {int limit});

final paginatedMediaWarmupProvider = Provider<PaginatedMediaWarmup>(
  (ref) => warmPaginatedMediaUris,
);

/// Absolute floor for load-more look-ahead (also scaled by viewport below).
const paginatedLoadMoreThresholdPx = 1200.0;

/// How many viewports ahead to start loading the next page.
const paginatedLoadMoreViewportFraction = 1.5;

/// Triggers [loadMore] when the scroll position nears the bottom.
///
/// Uses the larger of [threshold] and
/// `viewportDimension * [paginatedLoadMoreViewportFraction]` so fast
/// flings still get the next page before empty rows appear.
void handlePaginatedScroll(
  ScrollPosition position, {
  required bool isLoading,
  required bool hasMore,
  required VoidCallback loadMore,
  double threshold = paginatedLoadMoreThresholdPx,
}) {
  if (!position.hasContentDimensions) return;
  if (isLoading || !hasMore) return;

  final viewportLookahead =
      position.viewportDimension * paginatedLoadMoreViewportFraction;
  final effectiveThreshold = threshold > viewportLookahead
      ? threshold
      : viewportLookahead;

  if (position.pixels >= position.maxScrollExtent - effectiveThreshold) {
    loadMore();
  }
}

/// Resolve + warm OS thumbs for a freshly fetched page (idle priority).
void warmPaginatedMediaUris(Iterable<String> uris, {int limit = 16}) {
  final assetIds = uris.take(limit).toList(growable: false);
  if (assetIds.isEmpty) return;
  if (!usesFilesystemGallery) {
    for (final assetId in assetIds) {
      unawaited(AssetEntityCache.resolve(assetId));
    }
  }
  // Defer image precache to the next event-loop turn so the page insert
  // frame is not competing with decode work.
  scheduleMicrotask(() {
    ThumbnailPrefetcher.instance.warm(
      assetIds,
      limit: limit,
      thumbnailEdge: 256,
    );
  });
}

/// Paginated home feed backed by [MediaRepository.getHomeFeedPage].
class HomeFeedPaginatedNotifier
    extends AutoDisposeNotifier<PaginatedListState<FeedItem>> {
  @override
  PaginatedListState<FeedItem> build() {
    Future.microtask(() => loadMore(refresh: true));
    return const PaginatedListState();
  }

  Future<void> loadMore({bool refresh = false}) => loadPaginatedPage<FeedItem>(
    readState: () => state,
    writeState: (nextState) => state = nextState,
    fetchPage: (pageIndex) =>
        ref.read(mediaRepositoryProvider).getHomeFeedPage(pageIndex),
    pageSize: MediaRepository.pageSize,
    onPageLoaded: (items) => ref.read(paginatedMediaWarmupProvider)(
      items.map((item) => item.media.uri),
      limit: 12,
    ),
    refresh: refresh,
  );

  /// Updates favorite flag in-place without reloading the feed page.
  void setItemFavorite(int mediaId, bool isFavorite) {
    final items = [
      for (final item in state.items)
        if (item.media.id == mediaId)
          FeedItem(
            folderName: item.folderName,
            folderPath: item.folderPath,
            media: item.media.copyWith(isFavorite: isFavorite),
          )
        else
          item,
    ];
    state = state.copyWith(items: items);
  }
}

final homeFeedPaginatedProvider =
    NotifierProvider.autoDispose<
      HomeFeedPaginatedNotifier,
      PaginatedListState<FeedItem>
    >(HomeFeedPaginatedNotifier.new);

/// Paginated all-media grid (gallery view mode).
class GalleryPaginatedNotifier
    extends AutoDisposeNotifier<PaginatedListState<MediaItem>> {
  @override
  PaginatedListState<MediaItem> build() {
    Future.microtask(() => loadMore(refresh: true));
    return const PaginatedListState();
  }

  Future<void> loadMore({bool refresh = false}) => loadPaginatedPage<MediaItem>(
    readState: () => state,
    writeState: (nextState) => state = nextState,
    fetchPage: (pageIndex) =>
        ref.read(mediaRepositoryProvider).getGalleryMediaPage(pageIndex),
    pageSize: MediaRepository.pageSize,
    onPageLoaded: (items) =>
        ref.read(paginatedMediaWarmupProvider)(items.map((item) => item.uri)),
    refresh: refresh,
  );
}

final galleryPaginatedProvider =
    NotifierProvider.autoDispose<
      GalleryPaginatedNotifier,
      PaginatedListState<MediaItem>
    >(GalleryPaginatedNotifier.new);

/// Paginated explore/search results; [arg] is the search query string.
class ExplorePaginatedNotifier
    extends
        AutoDisposeFamilyNotifier<
          PaginatedListState<MediaItem>,
          ExploreSearchQuery
        > {
  @override
  PaginatedListState<MediaItem> build(ExploreSearchQuery query) {
    Future.microtask(() => loadMore(refresh: true));
    return const PaginatedListState();
  }

  Future<void> loadMore({bool refresh = false}) => loadPaginatedPage<MediaItem>(
    readState: () => state,
    writeState: (nextState) => state = nextState,
    fetchPage: (pageIndex) =>
        ref.read(mediaRepositoryProvider).searchExplorePage(arg, pageIndex),
    pageSize: MediaRepository.pageSize,
    onPageLoaded: (items) =>
        ref.read(paginatedMediaWarmupProvider)(items.map((item) => item.uri)),
    refresh: refresh,
  );
}

final explorePaginatedProvider = NotifierProvider.autoDispose
    .family<
      ExplorePaginatedNotifier,
      PaginatedListState<MediaItem>,
      ExploreSearchQuery
    >(ExplorePaginatedNotifier.new);

/// Paginated favorites grid.
class FavoritesPaginatedNotifier
    extends AutoDisposeNotifier<PaginatedListState<MediaItem>> {
  @override
  PaginatedListState<MediaItem> build() {
    Future.microtask(() => loadMore(refresh: true));
    return const PaginatedListState();
  }

  Future<void> loadMore({bool refresh = false}) => loadPaginatedPage<MediaItem>(
    readState: () => state,
    writeState: (nextState) => state = nextState,
    fetchPage: (pageIndex) =>
        ref.read(mediaRepositoryProvider).getFavoritesPage(pageIndex),
    pageSize: MediaRepository.pageSize,
    onPageLoaded: (items) =>
        ref.read(paginatedMediaWarmupProvider)(items.map((item) => item.uri)),
    refresh: refresh,
  );
}

final favoritesPaginatedProvider =
    NotifierProvider.autoDispose<
      FavoritesPaginatedNotifier,
      PaginatedListState<MediaItem>
    >(FavoritesPaginatedNotifier.new);

/// Paginated media for one album folder path.
class FolderMediaPaginatedNotifier
    extends AutoDisposeFamilyNotifier<PaginatedListState<MediaItem>, String> {
  @override
  PaginatedListState<MediaItem> build(String folderPath) {
    Future.microtask(() => loadMore(refresh: true));
    return const PaginatedListState();
  }

  Future<void> loadMore({bool refresh = false}) => loadPaginatedPage<MediaItem>(
    readState: () => state,
    writeState: (nextState) => state = nextState,
    fetchPage: (pageIndex) =>
        ref.read(mediaRepositoryProvider).getFolderMediaPage(arg, pageIndex),
    pageSize: MediaRepository.pageSize,
    onPageLoaded: (items) =>
        ref.read(paginatedMediaWarmupProvider)(items.map((item) => item.uri)),
    refresh: refresh,
  );
}

final folderMediaPaginatedProvider = NotifierProvider.autoDispose
    .family<
      FolderMediaPaginatedNotifier,
      PaginatedListState<MediaItem>,
      String
    >(FolderMediaPaginatedNotifier.new);

class ContentKindPaginatedNotifier
    extends
        AutoDisposeFamilyNotifier<
          PaginatedListState<MediaItem>,
          MediaContentKind
        > {
  String _ocrQuery = '';

  @override
  PaginatedListState<MediaItem> build(MediaContentKind kind) {
    Future.microtask(() => loadMore(refresh: true));
    return const PaginatedListState();
  }

  Future<void> setOcrQuery(String query) async {
    _ocrQuery = query.trim();
    await loadMore(refresh: true);
  }

  Future<void> loadMore({bool refresh = false}) => loadPaginatedPage<MediaItem>(
    readState: () => state,
    writeState: (nextState) => state = nextState,
    fetchPage: (pageIndex) => ref
        .read(mediaRepositoryProvider)
        .getContentKindPage(
          arg,
          pageIndex,
          ocrQuery: _ocrQuery.isEmpty ? null : _ocrQuery,
        ),
    pageSize: MediaRepository.pageSize,
    onPageLoaded: (items) =>
        ref.read(paginatedMediaWarmupProvider)(items.map((item) => item.uri)),
    refresh: refresh,
  );
}

final contentKindPaginatedProvider = NotifierProvider.autoDispose
    .family<
      ContentKindPaginatedNotifier,
      PaginatedListState<MediaItem>,
      MediaContentKind
    >(ContentKindPaginatedNotifier.new);
