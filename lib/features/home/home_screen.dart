import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/app/router.dart';
import 'package:social_gallery/data/repositories/media_repository.dart';
import 'package:social_gallery/domain/models/feed_item.dart';
import 'package:social_gallery/domain/models/folder_with_stories.dart';
import 'package:social_gallery/shared/widgets/empty_state.dart';
import 'package:social_gallery/shared/widgets/feed_post_card.dart';
import 'package:social_gallery/shared/widgets/floating_bottom_nav.dart';
import 'package:social_gallery/shared/widgets/stories_row.dart';

final homeStoriesProvider = FutureProvider<List<FolderWithStories>>((ref) {
  return ref.watch(mediaRepositoryProvider).getFoldersWithStories();
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();
  final List<FeedItem> _items = [];
  int _page = 0;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPage();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_loading &&
        _hasMore) {
      _loadPage();
    }
  }

  Future<void> _loadPage({bool refresh = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      if (refresh) {
        _page = 0;
        _items.clear();
        _hasMore = true;
      }
    });

    try {
      final repo = ref.read(mediaRepositoryProvider);
      final page = await repo.getHomeFeedPage(_page);
      setState(() {
        if (refresh) _items.clear();
        _items.addAll(page);
        _hasMore = page.length >= MediaRepository.pageSize;
        _page++;
        _loading = false;
      });
      if (refresh) {
        ref.invalidate(homeStoriesProvider);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggleFavorite(FeedItem item) async {
    final repo = ref.read(mediaRepositoryProvider);
    final next = !item.media.isFavorite;
    await repo.setFavorite(item.media.id, next);
    setState(() {
      final index = _items.indexWhere((i) => i.media.id == item.media.id);
      if (index >= 0) {
        _items[index] = FeedItem(
          folderName: item.folderName,
          folderPath: item.folderPath,
          media: item.media.copyWith(isFavorite: next),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final storiesAsync = ref.watch(homeStoriesProvider);

    return Scaffold(
      extendBody: true,
      appBar: AppBar(title: const Text('Home')),
      body: RefreshIndicator(
        onRefresh: () => _loadPage(refresh: true),
        child: _buildBody(storiesAsync),
      ),
    );
  }

  Widget _buildBody(AsyncValue<List<FolderWithStories>> storiesAsync) {
    final listPadding = FloatingNavInsets.scrollPadding(context);

    if (_error != null && _items.isEmpty) {
      return ListView(
        controller: _scrollController,
        padding: listPadding,
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.5,
            child: EmptyState(
              title: 'Could not load feed',
              message: _error,
              icon: Icons.error_outline,
            ),
          ),
        ],
      );
    }

    if (_items.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final stories = storiesAsync.maybeWhen(
      data: (folders) => folders,
      orElse: () => const <FolderWithStories>[],
    );

    if (_items.isEmpty) {
      return ListView(
        controller: _scrollController,
        padding: listPadding,
        children: [
          StoriesRow(
            folders: stories,
            onFolderTap: (path) => context.push(folderProfileLocation(path)),
            onCameraTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Camera capture coming soon')),
              );
            },
          ),
          const SizedBox(
            height: 400,
            child: EmptyState(
              title: 'No posts yet',
              message: 'Add folders to Home Feed in Manage Content.',
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: listPadding,
      itemCount: _items.length + 1 + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == 0) {
          return StoriesRow(
            folders: stories,
            onFolderTap: (path) => context.push(folderProfileLocation(path)),
            onCameraTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Camera capture coming soon')),
              );
            },
          );
        }

        final feedIndex = index - 1;
        if (feedIndex >= _items.length) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final item = _items[feedIndex];
        return FeedPostCard(
          item: item,
          onFolderTap: () => context.push(folderProfileLocation(item.folderPath)),
          onMediaTap: () => context.push(
            mediaViewerLocation(
              item.media.uri,
              mediaId: item.media.id,
              favorite: item.media.isFavorite,
            ),
          ),
          onFavoriteTap: () => _toggleFavorite(item),
        );
      },
    );
  }
}
