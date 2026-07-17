import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/app/router.dart';
import 'package:social_gallery/shared/navigation/media_viewer_session.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/core/animation/app_motion.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/core/utils/haptics.dart';
import 'package:social_gallery/domain/models/gallery_grouping_period.dart';
import 'package:social_gallery/domain/models/folder_info.dart';
import 'package:social_gallery/features/explore/explore_active_search_bar.dart';
import 'package:social_gallery/domain/models/explore_search_query.dart';
import 'package:social_gallery/features/explore/explore_search_helpers.dart';
import 'package:social_gallery/features/explore/explore_search_overlay.dart';
import 'package:social_gallery/features/explore/explore_recent_searches_provider.dart';
import 'package:social_gallery/core/auth/folder_access.dart';
import 'package:social_gallery/shared/widgets/folder_avatar.dart';
import 'package:social_gallery/shared/media/media_bulk_actions.dart';
import 'package:social_gallery/shared/pagination/paginated_list_notifier.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/domain/usecases/group_media_by_period.dart';
import 'package:social_gallery/shared/navigation/tab_scroll_to_top.dart';
import 'package:social_gallery/shared/widgets/empty_state.dart';
import 'package:social_gallery/shared/widgets/floating_bottom_nav.dart';
import 'package:social_gallery/shared/widgets/floating_selection_chrome.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';
import 'package:social_gallery/core/media/thumbnail_decode.dart';
import 'package:social_gallery/shared/media/thumbnail_prefetch.dart';
import 'package:social_gallery/shared/widgets/media_backup_badge.dart';
import 'package:social_gallery/shared/widgets/media_grid.dart';
import 'package:social_gallery/shared/widgets/media_thumbnail.dart';
import 'package:social_gallery/shared/widgets/motion/pressable_scale.dart';
import 'package:social_gallery/shared/widgets/motion/selection_chrome.dart';
// Wider thresholds so one deliberate pinch maps to one period step.
const _pinchZoomInThreshold = 0.78;
const _pinchZoomOutThreshold = 1.22;
/// Min horizontal movement before drag-select wins over scroll.
const _dragSelectThresholdPx = 12.0;

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  final _scrollController = ScrollController();
  final _groupMedia = GroupMediaByPeriod();
  GalleryGroupingPeriod _period = GalleryGroupingPeriod.day;

  final Set<int> _selectedIds = {};
  final Map<int, GlobalKey> _tileKeys = {};
  ExploreSearchQuery _searchQuery = const ExploreSearchQuery();
  List<FolderInfo> _folderSuggestions = [];
  int? _activeDragPointer;
  Offset? _dragStartPosition;
  bool _dragSelecting = false;
  bool? _dragSelectAdding;
  final Set<int> _dragVisitedIds = {};
  bool get _inSelectionMode => _selectedIds.isNotEmpty;
  bool get _isSearching => !_searchQuery.isEmpty;

  PaginatedListState<MediaItem> get _paginated => _isSearching
      ? ref.watch(explorePaginatedProvider(_searchQuery))
      : ref.watch(galleryPaginatedProvider);

  List<MediaItem> get _items => _paginated.items;

  void _setGallerySelectionActive(bool active) {
    if (ref.read(gallerySelectionActiveProvider) == active) return;
    ref.read(gallerySelectionActiveProvider.notifier).state = active;
  }

  void _syncGallerySelectionActive() {
    _setGallerySelectionActive(_selectedIds.isNotEmpty);
  }

  void _refreshMediaLists() {
    if (_isSearching) {
      ref
          .read(explorePaginatedProvider(_searchQuery).notifier)
          .loadMore(refresh: true);
    } else {
      ref.read(galleryPaginatedProvider.notifier).loadMore(refresh: true);
    }
  }

  /// Leaves selection mode immediately and returns a snapshot for the action.
  Set<int> _takeSelection() {
    final ids = Set<int>.of(_selectedIds);
    _exitSelectionMode();
    return ids;
  }

  void _toggleSelect(MediaItem item) {
    AppHaptics.medium();
    setState(() {
      if (_selectedIds.contains(item.id)) {
        _selectedIds.remove(item.id);
      } else {
        _selectedIds.add(item.id);
      }
    });
    _syncGallerySelectionActive();
  }

  void _startSelection(MediaItem item) {
    AppHaptics.medium();
    setState(() {
      _selectedIds.add(item.id);
    });
    _syncGallerySelectionActive();
  }

  void _exitSelectionMode() {
    setState(() {
      _selectedIds.clear();
      _resetDragSelectState();
    });
    _syncGallerySelectionActive();
  }

  GlobalKey _tileKeyFor(int id) => _tileKeys.putIfAbsent(id, GlobalKey.new);

  void _pruneTileKeys(Iterable<int> liveIds) {
    final live = liveIds is Set<int> ? liveIds : liveIds.toSet();
    _tileKeys.removeWhere((id, _) => !live.contains(id));
  }

  void _resetDragSelectState() {
    _activeDragPointer = null;
    _dragStartPosition = null;
    _dragSelecting = false;
    _dragSelectAdding = null;
    _dragVisitedIds.clear();
  }

  MediaItem? _itemById(int id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  int? _itemIdAt(Offset globalPosition) {
    int? bestId;
    var bestArea = double.infinity;
    for (final entry in _tileKeys.entries) {
      final box = entry.value.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize || !box.attached) continue;
      final rect = box.localToGlobal(Offset.zero) & box.size;
      if (!rect.contains(globalPosition)) continue;
      final area = rect.width * rect.height;
      // Prefer the smallest containing tile (avoids oversized wrappers).
      if (area < bestArea) {
        bestArea = area;
        bestId = entry.key;
      }
    }
    return bestId;
  }

  void _applyDragSelectAt(Offset globalPosition) {
    final itemId = _itemIdAt(globalPosition);
    if (itemId == null || _dragVisitedIds.contains(itemId)) return;

    final adding = _dragSelectAdding;
    if (adding == null) return;

    _dragVisitedIds.add(itemId);
    final changed = adding
        ? _selectedIds.add(itemId)
        : _selectedIds.remove(itemId);
    if (changed) {
      AppHaptics.selection();
      setState(() {});
      _syncGallerySelectionActive();
    }
  }

  void _handleSelectionPointerDown(PointerDownEvent event) {
    if (!_inSelectionMode) return;
    _pruneTileKeys(_items.map((item) => item.id));
    _activeDragPointer = event.pointer;
    _dragStartPosition = event.position;
    _dragSelecting = false;
    _dragSelectAdding = null;
    _dragVisitedIds.clear();
  }

  void _handleSelectionPointerMove(PointerMoveEvent event) {
    if (!_inSelectionMode || _activeDragPointer != event.pointer) return;

    final start = _dragStartPosition;
    if (start == null) return;

    final delta = event.position - start;

    if (!_dragSelecting) {
      // Vertical-dominant movement is a scroll — do not hijack it.
      if (delta.dy.abs() >= delta.dx.abs()) return;
      if (delta.dx.abs() < _dragSelectThresholdPx) return;

      final anchorId = _itemIdAt(start);
      if (anchorId == null) return;

      setState(() {
        _dragSelecting = true;
        _dragSelectAdding = !_selectedIds.contains(anchorId);
      });
      _applyDragSelectAt(start);
      _applyDragSelectAt(event.position);
      return;
    }

    _applyDragSelectAt(event.position);
  }

  void _handleSelectionPointerUp(PointerEvent event) {
    if (_activeDragPointer != event.pointer) return;
    // Taps are handled by the tile widgets; Listener only owns drag-select.
    setState(_resetDragSelectState);
  }

  Future<void> _bulkTrash() async {
    final ids = _takeSelection();
    if (ids.isEmpty) return;
    await bulkTrash(
      ref,
      context,
      ids,
      onDone: _refreshMediaLists,
    );
  }

  Future<void> _bulkMove() async {
    final ids = _takeSelection();
    if (ids.isEmpty) return;
    await bulkMove(
      ref,
      context,
      ids,
      onDone: _refreshMediaLists,
    );
  }

  Future<void> _createAlbumAndMove() async {
    final ids = _takeSelection();
    if (ids.isEmpty) return;
    await createAlbumAndMove(
      ref,
      context,
      ids,
      onDone: _refreshMediaLists,
    );
  }

  Future<void> _bulkFavorite(bool favorite) async {
    final ids = _takeSelection();
    if (ids.isEmpty) return;
    await bulkFavorite(
      ref,
      ids,
      favorite,
      onDone: _refreshMediaLists,
    );
  }

  Future<void> _bulkShare() async {
    final ids = _takeSelection();
    if (ids.isEmpty) return;
    await bulkShare(ref, context, ids);
  }

  Future<void> _copyToClipboard() async {
    final ids = _takeSelection();
    if (ids.isEmpty) return;
    await copyMediaToClipboard(ref, context, ids);
  }

  Future<void> _setAsWallpaper() async {
    final ids = _takeSelection();
    if (ids.isEmpty) return;
    await setMediaAsWallpaper(ref, context, ids);
  }

  Future<void> _showMoreActions() async {
    final showCopy = _selectedIds.length == 1;
    final single = showCopy ? _itemById(_selectedIds.first) : null;
    final showWallpaper = showCopy && (single == null || !single.isVideo);

    final action = await showSelectionMoreSheet(
      context: context,
      showCopy: showCopy,
      showWallpaper: showWallpaper,
    );
    if (!mounted || action == null) return;

    switch (action) {
      case SelectionMoreAction.favorite:
        await _bulkFavorite(true);
      case SelectionMoreAction.unfavorite:
        await _bulkFavorite(false);
      case SelectionMoreAction.createAlbum:
        await _createAlbumAndMove();
      case SelectionMoreAction.copyToClipboard:
        await _copyToClipboard();
      case SelectionMoreAction.setAsWallpaper:
        await _setAsWallpaper();
    }
  }

  bool _handlePinchZoomIn() {
    if (_inSelectionMode) return false;
    final next = _period.zoomIn();
    if (next == _period) return false;
    setState(() => _period = next);
    return true;
  }

  bool _handlePinchZoomOut() {
    if (_inSelectionMode) return false;
    final next = _period.zoomOut();
    if (next == _period) return false;
    setState(() => _period = next);
    return true;
  }

  void _openSearch() async {
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

  void _resetSearch() {
    if (_searchQuery.isEmpty && _folderSuggestions.isEmpty) return;
    setState(() {
      _searchQuery = const ExploreSearchQuery();
      _folderSuggestions = [];
    });
  }

  void _handleSearchBack() {
    AppHaptics.light();
    _resetSearch();
  }

  Future<void> _openFolderProfile(FolderInfo folder) async {
    final ok = await ensureFolderUnlocked(ref: ref, folder: folder);
    if (!ok || !mounted) return;

    _resetSearch();
    await context.push(folderProfileLocation(folder.path));
  }

  void _openMedia(MediaItem item) {
    openMediaViewer(context, ref, items: _items, item: item);
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _setGallerySelectionActive(false);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    final paginated = _isSearching
        ? ref.read(explorePaginatedProvider(_searchQuery))
        : ref.read(galleryPaginatedProvider);
    handlePaginatedScroll(
      _scrollController.position,
      isLoading: paginated.isLoading,
      hasMore: paginated.hasMore,
      loadMore: () {
        if (_isSearching) {
          ref
              .read(explorePaginatedProvider(_searchQuery).notifier)
              .loadMore();
        } else {
          ref.read(galleryPaginatedProvider.notifier).loadMore();
        }
      },
    );

    final columns = _columnCount(context);
    final width = MediaQuery.sizeOf(context).width;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cellLogical = (width - 4) / columns;
    final thumbEdge = thumbnailDecodeEdge(
      logicalWidth: cellLogical,
      devicePixelRatio: dpr,
      maxEdge: 320,
    );
    ThumbnailPrefetcher.instance.scheduleForGrid(
      metrics: _scrollController.position,
      assetIds: _items.map((e) => e.uri).toList(growable: false),
      crossAxisCount: columns,
      mainAxisExtent: cellLogical + 2,
      thumbnailEdge: thumbEdge,
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(syncStateProvider, (previous, current) {
      if (previous == true && current == false) {
        setState(_tileKeys.clear);
        if (_isSearching) {
          ref
              .read(explorePaginatedProvider(_searchQuery).notifier)
              .loadMore(refresh: true);
        } else {
          ref.read(galleryPaginatedProvider.notifier).loadMore(refresh: true);
        }
      }
    });

    final l10n = context.l10n;
    final motion = AppMotion.of(context, ref);
    final theme = Theme.of(context);
    final inSelectionMode = _inSelectionMode;

    listenForTabScrollToTop(
      ref,
      kShellTabHome,
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
        if (_inSelectionMode) {
          _exitSelectionMode();
          return true;
        }
        if (_isSearching) {
          _handleSearchBack();
          return true;
        }
        return false;
      },
      child: PopScope(
      canPop: !_inSelectionMode && !_isSearching,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _inSelectionMode) {
          _exitSelectionMode();
        } else if (!didPop && _isSearching) {
          _handleSearchBack();
        }
      },
      child: Scaffold(
        extendBody: true,
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
                    onTapQuery: _openSearch,
                    onRemoveLabel: () => _applySearch(
                      _searchQuery.copyWith(clearLabels: true),
                    ),
                    onRemoveColor: () => _applySearch(
                      _searchQuery.copyWith(clearColor: true),
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
                Expanded(
                  child: _GalleryPinchPeriodListener(
                    enabled: !inSelectionMode && !_isSearching,
                    onPinchZoomIn: _handlePinchZoomIn,
                    onPinchZoomOut: _handlePinchZoomOut,
                    child: _buildBody(theme, motion),
                  ),
                ),
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
                      heroTag: 'gallery_search',
                      tooltip: l10n.tooltipSearchGallery,
                      onPressed: _openSearch,
                      child: const Icon(Icons.search),
                    ),
                  ),
                ),
              ),
            if (inSelectionMode) ...[
              Positioned(
                top: 0,
                left: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: OneUiSpacing.sm,
                      left: OneUiSpacing.pageHorizontal,
                    ),
                    child: FloatingSelectionCountPill(
                      count: _selectedIds.length,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: OneUiSpacing.sm,
                      right: OneUiSpacing.pageHorizontal,
                    ),
                    child: FloatingSelectionCancelButton(
                      onPressed: _exitSelectionMode,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: FloatingSelectionActionBar(
                  onMove: _bulkMove,
                  onShare: _bulkShare,
                  onDelete: _bulkTrash,
                  onMore: _showMoreActions,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildBody(ThemeData theme, AppMotion motion) {
    final l10n = context.l10n;
    if (_paginated.error != null && _items.isEmpty) {
      return EmptyState(
        icon: Icons.error_outline,
        title: l10n.galleryErrorLoad,
        message: _paginated.error,
      );
    }

    if (_items.isEmpty && _paginated.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty) {
      return EmptyState(
        icon: Icons.photo_library_outlined,
        title: _isSearching ? l10n.galleryEmptySearchTitle : l10n.galleryEmptyTitle,
        message: _isSearching
            ? l10n.galleryEmptySearchMessage
            : l10n.galleryEmptyMessage,
      );
    }

    final navPadding = FloatingNavInsets.scrollPadding(context);
    final columns = _columnCount(context);
    final loadingMore = _paginated.isLoading && _paginated.hasMore;
    final inSelectionMode = _inSelectionMode;

    if (_isSearching) {
      return _buildSearchGrid(
        navPadding: navPadding,
        columns: columns,
        loadingMore: loadingMore,
        inSelectionMode: inSelectionMode,
      );
    }

    final groups = _groupMedia(items: _items, period: _period);

    Widget scrollContent = CustomScrollView(
      controller: _scrollController,
      cacheExtent: kMediaGridCacheExtent,
      physics: _dragSelecting
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      slivers: [
        for (var groupIndex = 0; groupIndex < groups.length; groupIndex++)
          ..._groupSlivers(
            theme: theme,
            group: groups[groupIndex],
            columns: columns,
            navPadding: navPadding,
            inSelectionMode: inSelectionMode,
          ),
        if (loadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.only(bottom: navPadding.bottom),
        ),
      ],
    );

    if (inSelectionMode) {
      scrollContent = Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _handleSelectionPointerDown,
        onPointerMove: _handleSelectionPointerMove,
        onPointerUp: _handleSelectionPointerUp,
        onPointerCancel: _handleSelectionPointerUp,
        child: scrollContent,
      );
    }

    return scrollContent;
  }

  Widget _buildSearchGrid({
    required EdgeInsets navPadding,
    required int columns,
    required bool loadingMore,
    required bool inSelectionMode,
  }) {
    Widget scrollContent = CustomScrollView(
      controller: _scrollController,
      cacheExtent: kMediaGridCacheExtent,
      physics: _dragSelecting
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            navPadding.left + 2,
            OneUiSpacing.sm,
            navPadding.right + 2,
            OneUiSpacing.sm,
          ),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = _items[index];
                return _GalleryTile(
                  key: _tileKeyFor(item.id),
                  item: item,
                  selected: _selectedIds.contains(item.id),
                  inSelectionMode: inSelectionMode,
                  onTap: inSelectionMode
                      ? () => _toggleSelect(item)
                      : () => _openMedia(item),
                  onLongPress:
                      inSelectionMode ? null : () => _startSelection(item),
                );
              },
              childCount: _items.length,
              addRepaintBoundaries: true,
            ),
          ),
        ),
        if (loadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.only(bottom: navPadding.bottom),
        ),
      ],
    );

    if (inSelectionMode) {
      scrollContent = Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _handleSelectionPointerDown,
        onPointerMove: _handleSelectionPointerMove,
        onPointerUp: _handleSelectionPointerUp,
        onPointerCancel: _handleSelectionPointerUp,
        child: scrollContent,
      );
    }

    return scrollContent;
  }

  int _columnCount(BuildContext context) {
    final base = _period.crossAxisCountForWidth(MediaQuery.sizeOf(context).width);
    if (!usesFilesystemGallery) {
      return base;
    }
    final gridSize = ref.watch(
      settingsProvider.select((s) => s.desktopGalleryGridSize),
    );
    return gridSize.adjustColumnCount(base);
  }

  List<Widget> _groupSlivers({
    required ThemeData theme,
    required MediaPeriodGroup group,
    required int columns,
    required EdgeInsets navPadding,
    required bool inSelectionMode,
  }) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            OneUiSpacing.pageHorizontal,
            OneUiSpacing.md,
            OneUiSpacing.pageHorizontal,
            OneUiSpacing.sm,
          ),
          child: Text(
            group.label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          navPadding.left + 2,
          0,
          navPadding.right + 2,
          OneUiSpacing.sm,
        ),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = group.items[index];
              return _GalleryTile(
                key: _tileKeyFor(item.id),
                item: item,
                selected: _selectedIds.contains(item.id),
                inSelectionMode: inSelectionMode,
                onTap: inSelectionMode
                    ? () => _toggleSelect(item)
                    : () => _openMedia(item),
                onLongPress:
                    inSelectionMode ? null : () => _startSelection(item),
              );
            },
            childCount: group.items.length,
            addRepaintBoundaries: true,
          ),
        ),
      ),
    ];
  }
}

class _GalleryTile extends ConsumerWidget {
  const _GalleryTile({
    super.key,
    required this.item,
    required this.selected,
    required this.inSelectionMode,
    required this.onTap,
    this.onLongPress,
  });

  final MediaItem item;
  final bool selected;
  final bool inSelectionMode;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncingMediaId = usesFilesystemGallery
        ? null
        : ref.watch(desktopBackupProvider.select((s) => s.syncingMediaId));
    final dpr = MediaQuery.devicePixelRatioOf(context);
    // Approximate cell from screen; LayoutBuilder inside MediaThumbnail
    // still clamps to the real painted width.
    final approxCell = MediaQuery.sizeOf(context).width / 3;
    final thumbEdge = thumbnailDecodeEdge(
      logicalWidth: approxCell,
      devicePixelRatio: dpr,
      maxEdge: 320,
    );

    return RepaintBoundary(
      child: PressableScale(
        enabled: onTap != null || onLongPress != null,
        animatePress: false,
        onTap: onTap,
        onLongPress: onLongPress,
        child: MediaSelectionOverlay(
          selected: selected,
          inSelectionMode: inSelectionMode,
          child: MediaThumbnail(
            assetId: item.uri,
            showVideoBadge: item.isVideo,
            maxThumbnailEdge: thumbEdge,
            backupState: visibleBackupState(
              item,
              syncingMediaId: syncingMediaId,
            ),
          ),
        ),
      ),
    );
  }
}

/// Tracks two-finger pinch distance via raw pointer events so scrolling still
/// works. [GestureDetector.onScaleUpdate] loses to [CustomScrollView] drag.
class _GalleryPinchPeriodListener extends StatefulWidget {
  const _GalleryPinchPeriodListener({
    required this.onPinchZoomIn,
    required this.onPinchZoomOut,
    required this.child,
    this.enabled = true,
  });

  final bool enabled;
  final bool Function() onPinchZoomIn;
  final bool Function() onPinchZoomOut;
  final Widget child;

  @override
  State<_GalleryPinchPeriodListener> createState() =>
      _GalleryPinchPeriodListenerState();
}

class _GalleryPinchPeriodListenerState
    extends State<_GalleryPinchPeriodListener> {
  final Map<int, Offset> _pointers = {};
  double? _pinchStartDistance;
  bool _periodChangedThisGesture = false;

  double? _pointerDistance() {
    if (_pointers.length < 2) return null;
    final positions = _pointers.values.toList(growable: false);
    return (positions[0] - positions[1]).distance;
  }

  void _syncPinchBaseline() {
    _pinchStartDistance = _pointers.length >= 2 ? _pointerDistance() : null;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (!widget.enabled) return;
    _pointers[event.pointer] = event.position;
    if (_pointers.length == 2) {
      _syncPinchBaseline();
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!widget.enabled) return;
    if (!_pointers.containsKey(event.pointer)) return;
    _pointers[event.pointer] = event.position;

    if (_periodChangedThisGesture) return;

    final startDistance = _pinchStartDistance;
    if (_pointers.length < 2 ||
        startDistance == null ||
        startDistance <= 0) {
      return;
    }

    final currentDistance = _pointerDistance();
    if (currentDistance == null) return;

    final scale = currentDistance / startDistance;
    if (scale <= _pinchZoomInThreshold) {
      if (widget.onPinchZoomOut()) {
        _periodChangedThisGesture = true;
      }
      _syncPinchBaseline();
    } else if (scale >= _pinchZoomOutThreshold) {
      if (widget.onPinchZoomIn()) {
        _periodChangedThisGesture = true;
      }
      _syncPinchBaseline();
    }
  }

  void _handlePointerUp(PointerEvent event) {
    _pointers.remove(event.pointer);
    if (_pointers.isEmpty) {
      _periodChangedThisGesture = false;
    }
    _syncPinchBaseline();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerUp,
      child: widget.child,
    );
  }
}
