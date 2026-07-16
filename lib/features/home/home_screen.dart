import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/app/router.dart';
import 'package:social_gallery/core/utils/haptics.dart';
import 'package:social_gallery/domain/models/feed_item.dart';
import 'package:social_gallery/domain/models/folder_with_stories.dart';
import 'package:social_gallery/features/home/home_providers.dart';
import 'package:social_gallery/shared/widgets/empty_state.dart';
import 'package:social_gallery/shared/widgets/feed_post_card.dart';
import 'package:social_gallery/shared/widgets/floating_bottom_nav.dart';
import 'package:social_gallery/shared/widgets/motion/staggered_entrance.dart';
import 'package:social_gallery/core/animation/app_motion.dart';
import 'package:social_gallery/shared/navigation/media_viewer_session.dart';
import 'package:social_gallery/shared/navigation/tab_scroll_to_top.dart';
import 'package:social_gallery/shared/pagination/paginated_list_notifier.dart';
import 'package:social_gallery/shared/widgets/stories_row.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();

  PaginatedListState<FeedItem> get _paginated =>
      ref.watch(homeFeedPaginatedProvider);

  List<FeedItem> get _items => _paginated.items;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final paginated = ref.read(homeFeedPaginatedProvider);
    handlePaginatedScroll(
      _scrollController.position,
      isLoading: paginated.isLoading,
      hasMore: paginated.hasMore,
      loadMore: () =>
          ref.read(homeFeedPaginatedProvider.notifier).loadMore(),
    );
  }

  Future<void> _refresh() async {
    await ref.read(homeFeedPaginatedProvider.notifier).loadMore(refresh: true);
    ref.invalidate(homeStoriesProvider);
  }

  Future<void> _toggleFavorite(FeedItem item) async {
    AppHaptics.light();
    final next = !item.media.isFavorite;
    ref
        .read(homeFeedPaginatedProvider.notifier)
        .setItemFavorite(item.media.id, next);
    try {
      await ref.read(mediaRepositoryProvider).setFavorite(item.media.id, next);
    } catch (_) {
      ref
          .read(homeFeedPaginatedProvider.notifier)
          .setItemFavorite(item.media.id, !next);
    }
  }

  Future<void> _shareMedia(FeedItem item) async {
    final media = item.media;
    if (usesFilesystemGallery) {
      final file = File(media.uri);
      if (file.existsSync()) {
        await Share.shareXFiles([XFile(file.path)], text: media.displayName);
      }
      return;
    }
    final entity = await AssetEntity.fromId(media.uri);
    if (entity == null) return;
    final file = await entity.file;
    if (file == null || !await file.exists()) return;
    await Share.shareXFiles([XFile(file.path)], text: media.displayName);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(syncStateProvider, (previous, current) {
      if (previous == true && current == false) {
        _refresh();
      }
    });

    final storiesAsync = ref.watch(homeStoriesProvider);
    final motion = AppMotion.of(context, ref);
    listenForTabScrollToTop(
      ref,
      kShellTabHome,
      _scrollController,
      motion: motion,
    );

    return Scaffold(
      extendBody: true,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _buildBody(storiesAsync),
      ),
    );
  }

  Widget _buildBody(AsyncValue<List<FolderWithStories>> storiesAsync) {
    final l10n = context.l10n;
    final listPadding = FloatingNavInsets.scrollPadding(context);

    if (_paginated.error != null && _items.isEmpty) {
      return ListView(
        controller: _scrollController,
        padding: listPadding,
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.4,
            child: EmptyState(
              title: l10n.homeErrorLoadFeed,
              message: _paginated.error,
              icon: Icons.error_outline,
            ),
          ),
        ],
      );
    }

    if (_items.isEmpty && _paginated.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final stories = storiesAsync.maybeWhen(
      data: (folders) => folders,
      orElse: () => const <FolderWithStories>[],
    );
    Widget storiesRow() {
      return StoriesRow(
        folders: stories,
        onFolderTap: (path) {
          AppHaptics.light();
          context.push(storyViewerLocation(path));
        },
        onCameraTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.snackbarCameraCaptureComingSoon)),
          );
        },
      );
    }

    if (_items.isEmpty) {
      return ListView(
        controller: _scrollController,
        padding: listPadding,
        children: [
          storiesRow(),
          SizedBox(
            height: 360,
            child: EmptyState(
              title: l10n.homeEmptyTitle,
              message: l10n.homeEmptyMessage,
            ),
          ),
        ],
      );
    }

    const headerCount = 1;

    return ListView.builder(
      controller: _scrollController,
      padding: listPadding,
      cacheExtent: 600,
      itemCount: headerCount + _items.length + (_paginated.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == 0) {
          return storiesRow();
        }

        final feedIndex = index - headerCount;
        if (feedIndex >= _items.length) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final item = _items[feedIndex];
        return StaggeredEntrance(
          key: ValueKey(item.media.id),
          index: feedIndex,
          playOnceKey: 'feed_${item.media.id}',
          child: FeedPostCard(
            item: item,
            onFolderTap: () =>
                context.push(folderProfileLocation(item.folderPath)),
            onMediaTap: () => openMediaViewer(
              context,
              ref,
              items: _items.map((entry) => entry.media).toList(),
              item: item.media,
            ),
            onFavoriteTap: () => _toggleFavorite(item),
            onShareTap: () => _shareMedia(item),
          ),
        );
      },
    );
  }
}
