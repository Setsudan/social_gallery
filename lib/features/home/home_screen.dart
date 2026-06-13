import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/app/router.dart';
import 'package:social_gallery/core/utils/haptics.dart';
import 'package:social_gallery/domain/models/feed_item.dart';
import 'package:social_gallery/domain/models/folder_info.dart';
import 'package:social_gallery/domain/models/folder_with_stories.dart';
import 'package:social_gallery/features/home/home_providers.dart';
import 'package:social_gallery/shared/widgets/account_folder_card.dart';
import 'package:social_gallery/shared/widgets/empty_state.dart';
import 'package:social_gallery/shared/widgets/feed_post_card.dart';
import 'package:social_gallery/shared/widgets/floating_bottom_nav.dart';
import 'package:social_gallery/shared/widgets/motion/staggered_entrance.dart';
import 'package:social_gallery/core/animation/app_motion.dart';
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
    ref.invalidate(homeAccountFoldersProvider);
  }

  Future<void> _toggleFavorite(FeedItem item) async {
    AppHaptics.light();
    final repo = ref.read(mediaRepositoryProvider);
    final next = !item.media.isFavorite;
    await repo.setFavorite(item.media.id, next);
    await _refresh();
  }

  Future<void> _shareMedia(FeedItem item) async {
    final media = item.media;
    if (Platform.isWindows) {
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
    final accountFoldersAsync = ref.watch(homeAccountFoldersProvider);
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
        child: _buildBody(storiesAsync, accountFoldersAsync),
      ),
    );
  }

  Widget _buildBody(
    AsyncValue<List<FolderWithStories>> storiesAsync,
    AsyncValue<List<FolderInfo>> accountFoldersAsync,
  ) {
    final listPadding = FloatingNavInsets.scrollPadding(context);

    if (_paginated.error != null && _items.isEmpty) {
      return ListView(
        controller: _scrollController,
        padding: listPadding,
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.4,
            child: EmptyState(
              title: 'Could not load feed',
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
    final accountFolders = accountFoldersAsync.maybeWhen(
      data: (folders) => folders,
      orElse: () => const <FolderInfo>[],
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
            const SnackBar(content: Text('Camera capture coming soon')),
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
          for (final folder in accountFolders)
            AccountFolderCard(
              folder: folder,
              onTap: () {
                AppHaptics.light();
                context.push(folderProfileLocation(folder.path));
              },
            ),
          if (accountFolders.isEmpty)
            const SizedBox(
              height: 360,
              child: EmptyState(
                title: 'No posts yet',
                message: 'Add folders to Home Feed in Manage Content.',
              ),
            ),
        ],
      );
    }

    final headerCount = 1 + accountFolders.length;

    return ListView.builder(
      controller: _scrollController,
      padding: listPadding,
      cacheExtent: 600,
      itemCount: headerCount + _items.length + (_paginated.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == 0) {
          return storiesRow();
        }

        if (index <= accountFolders.length) {
          final folder = accountFolders[index - 1];
          return AccountFolderCard(
            folder: folder,
            onTap: () {
              AppHaptics.light();
              context.push(folderProfileLocation(folder.path));
            },
          );
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
          index: feedIndex,
          playOnceKey: 'feed_${item.media.id}',
          child: FeedPostCard(
            item: item,
            onFolderTap: () =>
                context.push(folderProfileLocation(item.folderPath)),
            onMediaTap: () => context.push(
              mediaViewerLocation(
                item.media.uri,
                mediaId: item.media.id,
                favorite: item.media.isFavorite,
              ),
            ),
            onFavoriteTap: () => _toggleFavorite(item),
            onShareTap: () => _shareMedia(item),
          ),
        );
      },
    );
  }
}
