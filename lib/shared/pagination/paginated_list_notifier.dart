import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/media/asset_entity_cache.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';
import 'package:social_gallery/data/repositories/media_repository.dart';
import 'package:social_gallery/domain/models/feed_item.dart';
import 'package:social_gallery/domain/models/folder_info.dart';
import 'package:social_gallery/domain/models/explore_search_query.dart';
import 'package:social_gallery/domain/models/media_content_kind.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/features/home/home_providers.dart';
import 'package:social_gallery/shared/media/thumbnail_prefetch.dart';

const _feedRefreshDebounce = Duration(milliseconds: 300);

/// Stable signature of folder visibility fields that affect feed eligibility.
String folderFeedEligibilitySignature(List<FolderInfo> folders) {
  final sorted = [...folders]..sort((a, b) => a.path.compareTo(b.path));
  return sorted
      .map(
        (folder) =>
            '${folder.path}:${folder.followStatus.storageValue}:${folder.isBiometricLocked}:${folder.showInStories}',
      )
      .join('|');
}

/// Debounced listener that refreshes feeds when folder visibility changes.
final feedRefreshCoordinatorProvider = Provider<void>((ref) {
  Timer? debounce;

  ref.onDispose(() => debounce?.cancel());

  ref.listen<AsyncValue<List<FolderInfo>>>(allFoldersProvider, (
    previous,
    next,
  ) {
    final previousFolders = previous?.valueOrNull;
    final nextFolders = next.valueOrNull;
    if (previousFolders == null || nextFolders == null) return;

    if (folderFeedEligibilitySignature(previousFolders) ==
        folderFeedEligibilitySignature(nextFolders)) {
      return;
    }

    debounce?.cancel();
    debounce = Timer(_feedRefreshDebounce, () {
      refreshFeedProvidersFromRef(ref);
    });
  });
});

/// Refreshes home feed, gallery, explore, stories, and folder grids.
void refreshFeedProvidersFromRef(Ref ref) {
  if (ref.exists(homeFeedPaginatedProvider)) {
    unawaited(
      ref.read(homeFeedPaginatedProvider.notifier).loadMore(refresh: true),
    );
  } else {
    ref.invalidate(homeFeedPaginatedProvider);
  }

  if (ref.exists(galleryPaginatedProvider)) {
    unawaited(
      ref.read(galleryPaginatedProvider.notifier).loadMore(refresh: true),
    );
  } else {
    ref.invalidate(galleryPaginatedProvider);
  }

  ref.invalidate(explorePaginatedProvider);
  ref.invalidate(homeStoriesProvider);
  ref.invalidate(folderMediaPaginatedProvider);

  if (ref.exists(favoritesPaginatedProvider)) {
    unawaited(
      ref.read(favoritesPaginatedProvider.notifier).loadMore(refresh: true),
    );
  } else {
    ref.invalidate(favoritesPaginatedProvider);
  }
}

/// Widget-side alias for [refreshFeedProvidersFromRef].
void refreshFeedProviders(WidgetRef ref) {
  if (ref.exists(homeFeedPaginatedProvider)) {
    unawaited(
      ref.read(homeFeedPaginatedProvider.notifier).loadMore(refresh: true),
    );
  } else {
    ref.invalidate(homeFeedPaginatedProvider);
  }

  if (ref.exists(galleryPaginatedProvider)) {
    unawaited(
      ref.read(galleryPaginatedProvider.notifier).loadMore(refresh: true),
    );
  } else {
    ref.invalidate(galleryPaginatedProvider);
  }

  ref.invalidate(explorePaginatedProvider);
  ref.invalidate(homeStoriesProvider);
  ref.invalidate(folderMediaPaginatedProvider);

  if (ref.exists(favoritesPaginatedProvider)) {
    unawaited(
      ref.read(favoritesPaginatedProvider.notifier).loadMore(refresh: true),
    );
  } else {
    ref.invalidate(favoritesPaginatedProvider);
  }
}

/// Absolute floor for load-more look-ahead (also scaled by viewport below).
const paginatedLoadMoreThresholdPx = 1200.0;

/// How many viewports ahead to start loading the next page.
const paginatedLoadMoreViewportFraction = 1.5;

/// Shared state for infinite-scroll lists (home feed, gallery, explore).
class PaginatedListState<T> {
  const PaginatedListState({
    this.items = const [],
    this.page = 0,
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  final List<T> items;
  final int page;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  PaginatedListState<T> copyWith({
    List<T>? items,
    int? page,
    bool? isLoading,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) {
    return PaginatedListState<T>(
      items: items ?? this.items,
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

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
  final effectiveThreshold =
      threshold > viewportLookahead ? threshold : viewportLookahead;

  if (position.pixels >= position.maxScrollExtent - effectiveThreshold) {
    loadMore();
  }
}

/// Resolve + warm OS thumbs for a freshly fetched page (idle priority).
void warmPaginatedMediaUris(Iterable<String> uris, {int limit = 36}) {
  final ids = uris.take(limit).toList(growable: false);
  if (ids.isEmpty) return;
  if (!usesFilesystemGallery) {
    for (final id in ids) {
      unawaited(AssetEntityCache.resolve(id));
    }
  }
  // Defer image precache to the next event-loop turn so the page insert
  // frame is not competing with decode work.
  scheduleMicrotask(() {
    ThumbnailPrefetcher.instance.warm(ids, limit: limit, thumbnailEdge: 256);
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

  Future<void> loadMore({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      page: refresh ? 0 : null,
      hasMore: refresh ? true : null,
      items: refresh ? const [] : null,
    );

    try {
      final pageToLoad = refresh ? 0 : state.page;
      final page = await ref
          .read(mediaRepositoryProvider)
          .getHomeFeedPage(pageToLoad);
      final nextItems = refresh ? page : [...state.items, ...page];
      state = PaginatedListState(
        items: nextItems,
        page: pageToLoad + 1,
        isLoading: false,
        hasMore: page.length >= MediaRepository.pageSize,
      );
      warmPaginatedMediaUris(page.map((e) => e.media.uri), limit: 12);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        hasMore: refresh ? false : state.hasMore,
      );
    }
  }

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

final homeFeedPaginatedProvider = NotifierProvider.autoDispose<
    HomeFeedPaginatedNotifier, PaginatedListState<FeedItem>>(
  HomeFeedPaginatedNotifier.new,
);

/// Paginated all-media grid (gallery view mode).
class GalleryPaginatedNotifier
    extends AutoDisposeNotifier<PaginatedListState<MediaItem>> {
  @override
  PaginatedListState<MediaItem> build() {
    Future.microtask(() => loadMore(refresh: true));
    return const PaginatedListState();
  }

  Future<void> loadMore({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      page: refresh ? 0 : null,
      hasMore: refresh ? true : null,
      items: refresh ? const [] : null,
    );

    try {
      final pageToLoad = refresh ? 0 : state.page;
      final page = await ref
          .read(mediaRepositoryProvider)
          .getGalleryMediaPage(pageToLoad);
      final nextItems = refresh ? page : [...state.items, ...page];
      state = PaginatedListState(
        items: nextItems,
        page: pageToLoad + 1,
        isLoading: false,
        hasMore: page.length >= MediaRepository.pageSize,
      );
      warmPaginatedMediaUris(page.map((e) => e.uri));
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        hasMore: refresh ? false : state.hasMore,
      );
    }
  }
}

final galleryPaginatedProvider = NotifierProvider.autoDispose<
    GalleryPaginatedNotifier, PaginatedListState<MediaItem>>(
  GalleryPaginatedNotifier.new,
);

/// Paginated explore/search results; [arg] is the search query string.
class ExplorePaginatedNotifier
    extends AutoDisposeFamilyNotifier<PaginatedListState<MediaItem>, ExploreSearchQuery> {
  @override
  PaginatedListState<MediaItem> build(ExploreSearchQuery query) {
    Future.microtask(() => loadMore(refresh: true));
    return const PaginatedListState();
  }

  Future<void> loadMore({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      page: refresh ? 0 : null,
      hasMore: refresh ? true : null,
      items: refresh ? const [] : null,
    );

    try {
      final pageToLoad = refresh ? 0 : state.page;
      final page = await ref
          .read(mediaRepositoryProvider)
          .searchExplorePage(arg, pageToLoad);
      final nextItems = refresh ? page : [...state.items, ...page];
      state = PaginatedListState(
        items: nextItems,
        page: pageToLoad + 1,
        isLoading: false,
        hasMore: page.length >= MediaRepository.pageSize,
      );
      warmPaginatedMediaUris(page.map((e) => e.uri));
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        hasMore: refresh ? false : state.hasMore,
      );
    }
  }
}

final explorePaginatedProvider = NotifierProvider.autoDispose
    .family<ExplorePaginatedNotifier, PaginatedListState<MediaItem>, ExploreSearchQuery>(
  ExplorePaginatedNotifier.new,
);

/// Paginated favorites grid.
class FavoritesPaginatedNotifier
    extends AutoDisposeNotifier<PaginatedListState<MediaItem>> {
  @override
  PaginatedListState<MediaItem> build() {
    Future.microtask(() => loadMore(refresh: true));
    return const PaginatedListState();
  }

  Future<void> loadMore({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      page: refresh ? 0 : null,
      hasMore: refresh ? true : null,
      items: refresh ? const [] : null,
    );

    try {
      final pageToLoad = refresh ? 0 : state.page;
      final page = await ref
          .read(mediaRepositoryProvider)
          .getFavoritesPage(pageToLoad);
      final nextItems = refresh ? page : [...state.items, ...page];
      state = PaginatedListState(
        items: nextItems,
        page: pageToLoad + 1,
        isLoading: false,
        hasMore: page.length >= MediaRepository.pageSize,
      );
      warmPaginatedMediaUris(page.map((e) => e.uri));
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        hasMore: refresh ? false : state.hasMore,
      );
    }
  }
}

final favoritesPaginatedProvider = NotifierProvider.autoDispose<
    FavoritesPaginatedNotifier, PaginatedListState<MediaItem>>(
  FavoritesPaginatedNotifier.new,
);

/// Paginated media for one album folder path.
class FolderMediaPaginatedNotifier extends AutoDisposeFamilyNotifier<
    PaginatedListState<MediaItem>, String> {
  @override
  PaginatedListState<MediaItem> build(String folderPath) {
    Future.microtask(() => loadMore(refresh: true));
    return const PaginatedListState();
  }

  Future<void> loadMore({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      page: refresh ? 0 : null,
      hasMore: refresh ? true : null,
      items: refresh ? const [] : null,
    );

    try {
      final pageToLoad = refresh ? 0 : state.page;
      final page = await ref
          .read(mediaRepositoryProvider)
          .getFolderMediaPage(arg, pageToLoad);
      final nextItems = refresh ? page : [...state.items, ...page];
      state = PaginatedListState(
        items: nextItems,
        page: pageToLoad + 1,
        isLoading: false,
        hasMore: page.length >= MediaRepository.pageSize,
      );
      warmPaginatedMediaUris(page.map((e) => e.uri));
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        hasMore: refresh ? false : state.hasMore,
      );
    }
  }
}

final folderMediaPaginatedProvider = NotifierProvider.autoDispose
    .family<FolderMediaPaginatedNotifier, PaginatedListState<MediaItem>, String>(
  FolderMediaPaginatedNotifier.new,
);

class ContentKindPaginatedNotifier extends AutoDisposeFamilyNotifier<
    PaginatedListState<MediaItem>, MediaContentKind> {
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

  Future<void> loadMore({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      page: refresh ? 0 : null,
      hasMore: refresh ? true : null,
      items: refresh ? const [] : null,
    );

    try {
      final pageToLoad = refresh ? 0 : state.page;
      final page = await ref.read(mediaRepositoryProvider).getContentKindPage(
            arg,
            pageToLoad,
            ocrQuery: _ocrQuery.isEmpty ? null : _ocrQuery,
          );
      final nextItems = refresh ? page : [...state.items, ...page];
      state = PaginatedListState(
        items: nextItems,
        page: pageToLoad + 1,
        isLoading: false,
        hasMore: page.length >= MediaRepository.pageSize,
      );
      warmPaginatedMediaUris(page.map((e) => e.uri));
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        hasMore: refresh ? false : state.hasMore,
      );
    }
  }
}

final contentKindPaginatedProvider = NotifierProvider.autoDispose.family<
    ContentKindPaginatedNotifier, PaginatedListState<MediaItem>, MediaContentKind>(
  ContentKindPaginatedNotifier.new,
);
