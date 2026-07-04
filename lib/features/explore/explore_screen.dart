import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/app/router.dart';
import 'package:social_gallery/core/analysis/media_tagging_controller.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/core/utils/haptics.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';
import 'package:social_gallery/domain/models/explore_search_query.dart';
import 'package:social_gallery/domain/models/folder_info.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/features/explore/explore_active_search_bar.dart';
import 'package:social_gallery/features/explore/explore_recent_searches_provider.dart';
import 'package:social_gallery/features/explore/explore_search_helpers.dart';
import 'package:social_gallery/features/explore/explore_search_overlay.dart';
import 'package:social_gallery/shared/widgets/empty_state.dart';
import 'package:social_gallery/shared/widgets/folder_avatar.dart';
import 'package:social_gallery/core/animation/app_motion.dart';
import 'package:social_gallery/shared/navigation/media_viewer_session.dart';
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
  ExploreSearchQuery _searchQuery = const ExploreSearchQuery();
  final Set<int> _selectedIds = {};

  bool get _isSearching => !_searchQuery.isEmpty;

  void _handleSearchBack() {
    AppHaptics.light();
    _resetSearch();
  }

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
      _searchQuery = const ExploreSearchQuery();
      _folderSuggestions = [];
    });
  }

  Future<void> _openSearchOverlay() async {
    AppHaptics.light();
    final query = await ExploreSearchOverlay.show(
      context,
      initialQuery: _searchQuery,
    );
    if (!mounted) return;
    if (query == null) return;
    if (query.isEmpty) {
      _resetSearch();
      return;
    }
    await _applySearch(query);
  }

  Future<void> _applySearch(ExploreSearchQuery query) async {
    if (query.isEmpty) {
      _resetSearch();
      return;
    }

    final folderQuery = query.text.trim().isNotEmpty
        ? query.text.trim()
        : (query.label ?? '');
    final folders = folderQuery.isEmpty
        ? <FolderInfo>[]
        : await ref.read(folderRepositoryProvider).searchFolders(folderQuery);
    if (!mounted) return;

    setState(() {
      _searchQuery = query;
      _folderSuggestions = folders;
    });

    await ref
        .read(explorePaginatedProvider(query).notifier)
        .loadMore(refresh: true);
    if (!mounted) return;

    final items = ref.read(explorePaginatedProvider(query)).items;
    final thumbnailUri = items.isNotEmpty ? items.first.uri : null;
    final recentLabel = exploreSearchSummary(
      query: query,
      localize: (key) => _localizeSearchKey(key),
    );
    if (recentLabel.isNotEmpty) {
      await ref.read(recentSearchesProvider.notifier).add(
            recentLabel,
            thumbnailUri: thumbnailUri,
          );
    }
  }

  String _localizeSearchKey(String key) {
    final l10n = context.l10n;
    return switch (key) {
      'searchChipCat' => l10n.searchChipCat,
      'searchChipDog' => l10n.searchChipDog,
      'searchChipPerson' => l10n.searchChipPerson,
      'searchChipFood' => l10n.searchChipFood,
      'searchChipCar' => l10n.searchChipCar,
      'searchChipFlower' => l10n.searchChipFlower,
      'searchChipBottle' => l10n.searchChipBottle,
      'searchChipBird' => l10n.searchChipBird,
      'searchChipBeach' => l10n.searchChipBeach,
      'searchChipMountain' => l10n.searchChipMountain,
      'searchColorRed' => l10n.searchColorRed,
      'searchColorOrange' => l10n.searchColorOrange,
      'searchColorYellow' => l10n.searchColorYellow,
      'searchColorGreen' => l10n.searchColorGreen,
      'searchColorTeal' => l10n.searchColorTeal,
      'searchColorBlue' => l10n.searchColorBlue,
      'searchColorPurple' => l10n.searchColorPurple,
      'searchColorPink' => l10n.searchColorPink,
      'searchColorBrown' => l10n.searchColorBrown,
      'searchColorBlack' => l10n.searchColorBlack,
      'searchColorWhite' => l10n.searchColorWhite,
      'searchColorGray' => l10n.searchColorGray,
      _ => key,
    };
  }

  Future<void> _openFolderProfile(FolderInfo folder) async {
    final ok = await ensureFolderUnlocked(ref: ref, folder: folder);
    if (!ok || !mounted) return;

    _resetSearch();
    await context.push(folderProfileLocation(folder.path));
    if (!mounted) return;
    await ref
        .read(explorePaginatedProvider(const ExploreSearchQuery()).notifier)
        .loadMore(refresh: true);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final inSelectionMode = _selectedIds.isNotEmpty;
    final tagging = ref.watch(mediaTaggingControllerProvider);
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

    return BackButtonListener(
      onBackButtonPressed: () async {
        if (inSelectionMode) {
          setState(_selectedIds.clear);
          return true;
        }
        if (_isSearching) {
          _handleSearchBack();
          return true;
        }
        return false;
      },
      child: PopScope(
      canPop: !inSelectionMode && !_isSearching,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && inSelectionMode) {
          setState(_selectedIds.clear);
        } else if (!didPop && _isSearching) {
          _handleSearchBack();
        }
      },
      child: Scaffold(
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
              if (!inSelectionMode && _isSearching)
                ExploreActiveSearchBar(
                  query: _searchQuery,
                  onBack: _handleSearchBack,
                  onClear: _handleSearchBack,
                  onTapQuery: _openSearchOverlay,
                  onRemoveLabel: () => _applySearch(
                    _searchQuery.copyWith(clearLabel: true),
                  ),
                  onRemoveColor: () => _applySearch(
                    _searchQuery.copyWith(clearColor: true),
                  ),
                ),
              if (!inSelectionMode && tagging.isScanning)
                MaterialBanner(
                  content: Text(
                    l10n.searchIndexingProgress(tagging.scanned, tagging.total),
                  ),
                  leading: const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  actions: const [SizedBox.shrink()],
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
          if (!inSelectionMode && !_isSearching)
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
                    tooltip: l10n.tooltipSearch,
                    onPressed: _openSearchOverlay,
                    child: const Icon(Icons.search),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
    ),
    );
  }

  Widget _buildGrid() {
    final l10n = context.l10n;
    final tagging = ref.watch(mediaTaggingControllerProvider);
    if (_paginated.isLoading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_paginated.error != null && _items.isEmpty) {
      return EmptyState(
        title: l10n.exploreErrorLoad,
        message: _paginated.error,
        icon: Icons.error_outline,
      );
    }
    if (_items.isEmpty) {
      final indexing = tagging.isScanning && _searchQuery.hasContentFilters;
      return EmptyState(
        title: l10n.exploreEmptyTitle,
        message: _isSearching
            ? (indexing
                ? l10n.exploreEmptyMessageIndexing
                : l10n.exploreEmptyMessageSearch)
            : l10n.exploreEmptyMessageNoSearch,
      );
    }
    final loadingMore = _paginated.isLoading && _items.isNotEmpty;

    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width > 800 || usesFilesystemGallery;

    final Widget grid = isDesktop
        ? MediaGrid(
            controller: _scrollController,
            items: _items,
            selectedIds: _selectedIds,
            onSelectToggle: _toggleSelect,
            onLongPress: _startSelection,
            onTap: (item) => openMediaViewer(
              context,
              ref,
              items: _items,
              item: item,
            ),
          )
        : ExploreMosaicGrid(
            controller: _scrollController,
            items: _items,
            showLoadingFooter: loadingMore && _paginated.hasMore,
            selectedIds: _selectedIds,
            onSelectToggle: _toggleSelect,
            onLongPress: _startSelection,
            onTap: (item) => openMediaViewer(
              context,
              ref,
              items: _items,
              item: item,
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
