import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/data/repositories/media_repository.dart';
import 'package:social_gallery/domain/models/feed_item.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/features/home/home_providers.dart';

void refreshFeedProvidersFromRef(Ref ref) {
  if (ref.exists(homeFeedPaginatedProvider)) {
    unawaited(
      ref.read(homeFeedPaginatedProvider.notifier).loadMore(refresh: true),
    );
  } else {
    ref.invalidate(homeFeedPaginatedProvider);
  }

  ref.invalidate(explorePaginatedProvider);
  ref.invalidate(homeStoriesProvider);
  ref.invalidate(homeAccountFoldersProvider);
}

void refreshFeedProviders(WidgetRef ref) {
  if (ref.exists(homeFeedPaginatedProvider)) {
    unawaited(
      ref.read(homeFeedPaginatedProvider.notifier).loadMore(refresh: true),
    );
  } else {
    ref.invalidate(homeFeedPaginatedProvider);
  }

  ref.invalidate(explorePaginatedProvider);
  ref.invalidate(homeStoriesProvider);
  ref.invalidate(homeAccountFoldersProvider);
}

const paginatedLoadMoreThresholdPx = 400.0;

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

void handlePaginatedScroll(
  ScrollPosition position, {
  required bool isLoading,
  required bool hasMore,
  required VoidCallback loadMore,
  double threshold = paginatedLoadMoreThresholdPx,
}) {
  if (!position.hasContentDimensions) return;
  if (position.pixels >= position.maxScrollExtent - threshold &&
      !isLoading &&
      hasMore) {
    loadMore();
  }
}

class HomeFeedPaginatedNotifier
    extends AutoDisposeNotifier<PaginatedListState<FeedItem>> {
  @override
  PaginatedListState<FeedItem> build() {
    Future.microtask(() => loadMore(refresh: true));
    return const PaginatedListState();
  }

  Future<void> loadMore({bool refresh = false}) async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      page: refresh ? 0 : null,
      hasMore: refresh ? true : null,
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
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        hasMore: refresh ? false : state.hasMore,
      );
    }
  }
}

final homeFeedPaginatedProvider = NotifierProvider.autoDispose<
    HomeFeedPaginatedNotifier, PaginatedListState<FeedItem>>(
  HomeFeedPaginatedNotifier.new,
);

class GalleryPaginatedNotifier
    extends AutoDisposeNotifier<PaginatedListState<MediaItem>> {
  @override
  PaginatedListState<MediaItem> build() {
    Future.microtask(() => loadMore(refresh: true));
    return const PaginatedListState();
  }

  Future<void> loadMore({bool refresh = false}) async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      page: refresh ? 0 : null,
      hasMore: refresh ? true : null,
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

class ExplorePaginatedNotifier
    extends AutoDisposeFamilyNotifier<PaginatedListState<MediaItem>, String> {
  @override
  PaginatedListState<MediaItem> build(String query) {
    Future.microtask(() => loadMore(refresh: true));
    return const PaginatedListState();
  }

  Future<void> loadMore({bool refresh = false}) async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      page: refresh ? 0 : null,
      hasMore: refresh ? true : null,
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
    .family<ExplorePaginatedNotifier, PaginatedListState<MediaItem>, String>(
  ExplorePaginatedNotifier.new,
);
