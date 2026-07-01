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
import 'package:social_gallery/features/explore/explore_search_overlay.dart';
import 'package:social_gallery/features/explore/explore_recent_searches_provider.dart';
import 'package:social_gallery/core/auth/folder_access.dart';
import 'package:social_gallery/shared/widgets/folder_avatar.dart';
import 'package:social_gallery/shared/media/media_bulk_actions.dart';
import 'package:social_gallery/shared/pagination/paginated_list_notifier.dart';
import 'package:social_gallery/shared/widgets/media_selection_app_bar.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/domain/usecases/group_media_by_period.dart';
import 'package:social_gallery/shared/navigation/tab_scroll_to_top.dart';
import 'package:social_gallery/shared/widgets/empty_state.dart';
import 'package:social_gallery/shared/widgets/floating_bottom_nav.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';
import 'package:social_gallery/shared/widgets/media_backup_badge.dart';
import 'package:social_gallery/shared/widgets/media_thumbnail.dart';
import 'package:social_gallery/shared/widgets/motion/pressable_scale.dart';
import 'package:social_gallery/shared/widgets/motion/selection_chrome.dart';
// Wider thresholds so one deliberate pinch maps to one period step.
const _pinchZoomInThreshold = 0.78;
const _pinchZoomOutThreshold = 1.22;
const _dragSelectThresholdPx = 8.0;

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
  String _searchQuery = '';
  List<FolderInfo> _folderSuggestions = [];
  int? _activeDragPointer;
  Offset? _dragStartPosition;
  bool _dragSelecting = false;
  bool? _dragSelectAdding;
  final Set<int> _dragVisitedIds = {};
  bool get _inSelectionMode => _selectedIds.isNotEmpty;
  bool get _isSearching => _searchQuery.isNotEmpty;

  PaginatedListState<MediaItem> get _paginated => _isSearching
      ? ref.watch(explorePaginatedProvider(_searchQuery))
      : ref.watch(galleryPaginatedProvider);

  List<MediaItem> get _items => _paginated.items;

  void _clearSelectionAndRefresh() {
    setState(_selectedIds.clear);
    if (_isSearching) {
      ref
          .read(explorePaginatedProvider(_searchQuery).notifier)
          .loadMore(refresh: true);
    } else {
      ref.read(galleryPaginatedProvider.notifier).loadMore(refresh: true);
    }
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
  }

  void _startSelection(MediaItem item) {
    AppHaptics.medium();
    setState(() {
      _selectedIds.add(item.id);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectedIds.clear();
      _resetDragSelectState();
    });
  }

  GlobalKey _tileKeyFor(int id) => _tileKeys.putIfAbsent(id, GlobalKey.new);

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
    for (final entry in _tileKeys.entries) {
      final box = entry.value.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      final rect = box.localToGlobal(Offset.zero) & box.size;
      if (rect.contains(globalPosition)) {
        return entry.key;
      }
    }
    return null;
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
    }
  }

  void _handleSelectionPointerDown(PointerDownEvent event) {
    if (!_inSelectionMode) return;
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

    if (!_dragSelecting) {
      if ((event.position - start).distance < _dragSelectThresholdPx) return;

      final anchorId = _itemIdAt(start);
      if (anchorId == null) return;

      setState(() {
        _dragSelecting = true;
        _dragSelectAdding = !_selectedIds.contains(anchorId);
      });
      _applyDragSelectAt(start);
      return;
    }

    _applyDragSelectAt(event.position);
  }

  void _handleSelectionPointerUp(PointerEvent event) {
    if (_activeDragPointer != event.pointer) return;

    if (!_dragSelecting) {
      final itemId = _itemIdAt(event.position);
      if (itemId != null) {
        final item = _itemById(itemId);
        if (item != null) _toggleSelect(item);
      }
    }

    setState(_resetDragSelectState);
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

  Future<void> _createAlbumAndMove() => createAlbumAndMove(
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

  void _resetSearch() {
    if (_searchQuery.isEmpty && _folderSuggestions.isEmpty) return;
    setState(() {
      _searchQuery = '';
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
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
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
        appBar: AnimatedMediaSelectionAppBar(
          visible: inSelectionMode,
          selectedCount: _selectedIds.length,
          duration: motion.fade,
          curve: motion.enterCurve,
          onCancel: _exitSelectionMode,
          onFavorite: () => _bulkFavorite(true),
          onUnfavorite: () => _bulkFavorite(false),
          onMove: _bulkMove,
          onTrash: _bulkTrash,
          onCreateAlbum: _createAlbumAndMove,
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
                    onTapQuery: _openSearch,
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
      cacheExtent: 800,
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
      cacheExtent: 800,
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
                  onTap: inSelectionMode ? null : () => _openMedia(item),
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
                onTap: inSelectionMode ? null : () => _openMedia(item),
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

    return RepaintBoundary(
      child: PressableScale(
        enabled: onTap != null || onLongPress != null,
        onTap: onTap,
        onLongPress: onLongPress,
        child: MediaSelectionOverlay(
          selected: selected,
          inSelectionMode: inSelectionMode,
          child: MediaThumbnail(
            assetId: item.uri,
            showVideoBadge: item.isVideo,
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
