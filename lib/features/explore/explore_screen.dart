import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/app/router.dart';
import 'package:social_gallery/core/utils/haptics.dart';
import 'package:social_gallery/domain/models/folder_info.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/features/explore/explore_recent_searches_provider.dart';
import 'package:social_gallery/features/explore/explore_search_overlay.dart';
import 'package:social_gallery/shared/widgets/empty_state.dart';
import 'package:social_gallery/shared/widgets/folder_avatar.dart';
import 'package:social_gallery/core/animation/app_motion.dart';
import 'package:social_gallery/shared/navigation/tab_scroll_to_top.dart';
import 'package:social_gallery/core/auth/folder_access.dart';
import 'package:social_gallery/shared/widgets/explore_mosaic_grid.dart';
import 'package:social_gallery/shared/media/media_bulk_actions.dart';
import 'package:social_gallery/shared/pagination/paginated_list_notifier.dart';
import 'package:social_gallery/shared/widgets/media_grid.dart';
import 'package:social_gallery/shared/widgets/media_selection_app_bar.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _scrollController = ScrollController();
  List<FolderInfo> _folderSuggestions = [];
  String _searchQuery = '';
  final Set<int> _selectedIds = {};

  PaginatedListState<MediaItem> get _paginated =>
      ref.watch(explorePaginatedProvider(_searchQuery));

  List<MediaItem> get _items => _paginated.items;

  void _clearSelectionAndRefresh() {
    setState(_selectedIds.clear);
    ref
        .read(explorePaginatedProvider(_searchQuery).notifier)
        .loadMore(refresh: true);
  }

  void _toggleSelect(MediaItem item) {
    setState(() {
      if (_selectedIds.contains(item.id)) {
        _selectedIds.remove(item.id);
      } else {
        _selectedIds.add(item.id);
      }
    });
  }

  void _startSelection(MediaItem item) {
    setState(() {
      _selectedIds.add(item.id);
    });
  }

  Future<void> _bulkTrash() => bulkTrash(
        ref,
        context,
        _selectedIds,
        onDone: _clearSelectionAndRefresh,
      );

  Future<void> _bulkMove() => bulkMove(
        ref,
        context,
        _selectedIds,
        onDone: _clearSelectionAndRefresh,
      );

  Future<void> _bulkCreateAlbumAndMove() => createAlbumAndMove(
        ref,
        context,
        _selectedIds,
        onDone: _clearSelectionAndRefresh,
      );

  Future<void> _bulkFavorite(bool favorite) => bulkFavorite(
        ref,
        _selectedIds,
        favorite,
        onDone: _clearSelectionAndRefresh,
      );

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final paginated = ref.read(explorePaginatedProvider(_searchQuery));
    handlePaginatedScroll(
      _scrollController.position,
      isLoading: paginated.isLoading,
      hasMore: paginated.hasMore,
      loadMore: () => ref
          .read(explorePaginatedProvider(_searchQuery).notifier)
          .loadMore(),
    );
  }

  void _resetSearch() {
    if (_searchQuery.isEmpty && _folderSuggestions.isEmpty) {
      return;
    }
    setState(() {
      _searchQuery = '';
      _folderSuggestions = [];
    });
  }

  Future<void> _openSearchOverlay() async {
    AppHaptics.light();
    final query = await ExploreSearchOverlay.show(
      context,
      initialQuery: _searchQuery,
    );
    if (!mounted || query == null) return;
    await _applySearch(query);
  }

  Future<void> _applySearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _resetSearch();
      return;
    }

    final folders =
        await ref.read(folderRepositoryProvider).searchFolders(trimmed);
    if (!mounted) return;

    setState(() {
      _searchQuery = trimmed;
      _folderSuggestions = folders;
    });

    await ref
        .read(explorePaginatedProvider(trimmed).notifier)
        .loadMore(refresh: true);
    if (!mounted) return;

    final items = ref.read(explorePaginatedProvider(trimmed)).items;
    final thumbnailUri = items.isNotEmpty ? items.first.uri : null;
    await ref.read(recentSearchesProvider.notifier).add(
          trimmed,
          thumbnailUri: thumbnailUri,
        );
  }

  Future<void> _openFolderProfile(FolderInfo folder) async {
    final ok = await ensureFolderUnlocked(ref: ref, folder: folder);
    if (!ok || !mounted) return;

    _resetSearch();
    await context.push(folderProfileLocation(folder.path));
    if (!mounted) return;
    await ref.read(explorePaginatedProvider('').notifier).loadMore(refresh: true);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inSelectionMode = _selectedIds.isNotEmpty;
    final motion = AppMotion.of(context, ref);
    listenForTabScrollToTop(
      ref,
      kShellTabExplore,
      _scrollController,
      motion: motion,
    );
    ref.listen<int>(exploreSearchResetProvider, (previous, next) {
      if (previous != null && previous != next) {
        _resetSearch();
      }
    });

    return Scaffold(
      extendBody: true,
      appBar: AnimatedMediaSelectionAppBar(
        visible: inSelectionMode,
        selectedCount: _selectedIds.length,
        duration: motion.fade,
        curve: motion.enterCurve,
        onCancel: () => setState(_selectedIds.clear),
        onFavorite: () => _bulkFavorite(true),
        onUnfavorite: () => _bulkFavorite(false),
        onMove: _bulkMove,
        onTrash: _bulkTrash,
        onCreateAlbum: _bulkCreateAlbumAndMove,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!inSelectionMode && _searchQuery.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    OneUiSpacing.pageHorizontal,
                    OneUiSpacing.sm,
                    OneUiSpacing.pageHorizontal,
                    OneUiSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ActionChip(
                          avatar: const Icon(Icons.search, size: 18),
                          label: Text(_searchQuery),
                          onPressed: _openSearchOverlay,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Clear search',
                        onPressed: _resetSearch,
                      ),
                    ],
                  ),
                ),
              if (!inSelectionMode && _folderSuggestions.isNotEmpty)
                SizedBox(
                  height: 56,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _folderSuggestions.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final folder = _folderSuggestions[index];
                      return ActionChip(
                        avatar: FolderAvatar(
                          name: folder.name,
                          size: 28,
                          coverUri: folder.isLockedAccount
                              ? null
                              : folder.displayCoverUri,
                          locked: folder.isLockedAccount,
                        ),
                        label: Text(folder.name),
                        onPressed: () => _openFolderProfile(folder),
                      );
                    },
                  ),
                ),
              Expanded(child: _buildGrid()),
            ],
          ),
          if (!inSelectionMode)
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: OneUiSpacing.sm,
                    right: OneUiSpacing.pageHorizontal,
                  ),
                  child: FloatingActionButton.small(
                    heroTag: 'explore_search',
                    tooltip: 'Search',
                    onPressed: _openSearchOverlay,
                    child: const Icon(Icons.search),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    if (_paginated.isLoading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_paginated.error != null && _items.isEmpty) {
      return EmptyState(
        title: 'Could not load library',
        message: _paginated.error,
        icon: Icons.error_outline,
      );
    }
    if (_items.isEmpty) {
      return const EmptyState(
        title: 'No media found',
        message: 'Try a different search or add folders to Home Feed.',
      );
    }
    final loadingMore = _paginated.isLoading && _items.isNotEmpty;

    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width > 800 || Platform.isWindows;

    final Widget grid = isDesktop
        ? MediaGrid(
            controller: _scrollController,
            items: _items,
            selectedIds: _selectedIds,
            onSelectToggle: _toggleSelect,
            onLongPress: _startSelection,
            onTap: (item) => context.push(
              mediaViewerLocation(
                item.uri,
                mediaId: item.id,
                favorite: item.isFavorite,
              ),
            ),
          )
        : ExploreMosaicGrid(
            controller: _scrollController,
            items: _items,
            showLoadingFooter: loadingMore && _paginated.hasMore,
            selectedIds: _selectedIds,
            onSelectToggle: _toggleSelect,
            onLongPress: _startSelection,
            onTap: (item) => context.push(
              mediaViewerLocation(
                item.uri,
                mediaId: item.id,
                favorite: item.isFavorite,
              ),
            ),
          );

    return RefreshIndicator(
      onRefresh: () => ref
          .read(explorePaginatedProvider(_searchQuery).notifier)
          .loadMore(refresh: true),
      child: grid,
    );
  }
}
