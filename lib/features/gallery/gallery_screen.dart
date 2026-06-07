import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/app/router.dart';
import 'package:social_gallery/core/animation/app_motion.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/core/utils/haptics.dart';
import 'package:social_gallery/core/utils/media_hero.dart';
import 'package:social_gallery/data/repositories/media_repository.dart';
import 'package:social_gallery/domain/models/gallery_grouping_period.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/domain/usecases/group_media_by_period.dart';
import 'package:social_gallery/shared/navigation/tab_scroll_to_top.dart';
import 'package:social_gallery/shared/widgets/empty_state.dart';
import 'package:social_gallery/shared/widgets/floating_bottom_nav.dart';
import 'package:social_gallery/shared/widgets/folder_picker_sheet.dart';
import 'package:social_gallery/shared/widgets/media_thumbnail.dart';
import 'package:social_gallery/shared/widgets/motion/pressable_scale.dart';
import 'package:social_gallery/shared/widgets/motion/selection_chrome.dart';
// Wider thresholds so one deliberate pinch maps to one period step.
const _pinchZoomInThreshold = 0.78;
const _pinchZoomOutThreshold = 1.22;
const _loadMoreThresholdPx = 400.0;
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

  final List<MediaItem> _items = [];
  final Set<int> _selectedIds = {};
  final Map<int, GlobalKey> _tileKeys = {};
  int? _activeDragPointer;
  Offset? _dragStartPosition;
  bool _dragSelecting = false;
  bool? _dragSelectAdding;
  final Set<int> _dragVisitedIds = {};
  int _page = 0;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;

  bool get _inSelectionMode => _selectedIds.isNotEmpty;

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

  Future<List<MediaItem>> _selectedItems() async {
    final repo = ref.read(mediaRepositoryProvider);
    final items = <MediaItem>[];
    for (final id in _selectedIds) {
      final item = await repo.getMediaById(id);
      if (item != null) items.add(item);
    }
    return items;
  }

  Future<void> _bulkTrash() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to trash'),
        content: Text(
          'Move ${_selectedIds.length} items to trash? You can restore them from Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Move to trash'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final repo = ref.read(mediaRepositoryProvider);
    final items = await _selectedItems();
    await repo.trashMedia(items);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Moved ${items.length} item(s) to trash')),
    );
    setState(_selectedIds.clear);
    await _loadPage(refresh: true);
  }

  Future<void> _bulkMove() async {
    final folders = await ref.read(folderRepositoryProvider).watchAll().first;
    if (!mounted) return;

    final targetPath = await showFolderPickerSheet(
      context: context,
      ref: ref,
      folders: folders,
    );

    if (targetPath == null) return;

    final repo = ref.read(mediaRepositoryProvider);
    final items = await _selectedItems();
    await repo.moveMedia(items, targetPath);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Moved ${items.length} item(s)')),
    );
    setState(_selectedIds.clear);
    await _loadPage(refresh: true);
  }

  Future<void> _createAlbumAndMove() async {
    final nameController = TextEditingController();
    final albumName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create album'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Album name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) Navigator.pop(context, name);
            },
            child: const Text('Create and move'),
          ),
        ],
      ),
    );

    if (albumName == null || albumName.isEmpty) return;

    final repo = ref.read(mediaRepositoryProvider);
    final items = await _selectedItems();
    final ok = await repo.createFolderAndMoveMedia(albumName, items);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Created "$albumName" and moved ${items.length} item(s)'
              : 'Could not create album. Check storage access.',
        ),
      ),
    );
    setState(_selectedIds.clear);
    await _loadPage(refresh: true);
  }

  Future<void> _bulkFavorite(bool favorite) async {
    final repo = ref.read(mediaRepositoryProvider);
    for (final id in _selectedIds) {
      await repo.setFavorite(id, favorite);
    }
    setState(_selectedIds.clear);
    await _loadPage(refresh: true);
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

  void _openSearch() {
    context.go('/explore');
  }

  void _openMedia(MediaItem item) {
    context.push(
      postDetailLocation(item.uri, mediaId: item.id, favorite: item.isFavorite),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadPage();
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
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThresholdPx &&
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
        _tileKeys.clear();
        _hasMore = true;
      }
    });

    final pageToLoad = refresh ? 0 : _page;

    try {
      final repo = ref.read(mediaRepositoryProvider);
      final page = await repo.getGalleryMediaPage(pageToLoad);
      if (!mounted) return;
      setState(() {
        if (refresh) _items.clear();
        _items.addAll(page);
        _hasMore = page.length >= MediaRepository.pageSize;
        _page = pageToLoad + 1;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        if (refresh) _hasMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(syncStateProvider, (previous, current) {
      if (previous == true && current == false) {
        _loadPage(refresh: true);
      }
    });

    final motion = AppMotion.of(context, ref);
    final theme = Theme.of(context);
    final inSelectionMode = _inSelectionMode;

    listenForTabScrollToTop(
      ref,
      kShellTabHome,
      _scrollController,
      motion: motion,
    );

    return PopScope(
      canPop: !inSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && inSelectionMode) {
          _exitSelectionMode();
        }
      },
      child: Scaffold(
        extendBody: true,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(inSelectionMode ? kToolbarHeight : 0),
          child: AnimatedSize(
            duration: motion.fade,
            curve: motion.enterCurve,
            alignment: Alignment.topCenter,
            child: inSelectionMode
                ? AppBar(
                    title: Text('${_selectedIds.length} selected'),
                    leading: IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Cancel selection',
                      onPressed: _exitSelectionMode,
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.favorite),
                        tooltip: 'Favorite selected',
                        onPressed: () => _bulkFavorite(true),
                      ),
                      IconButton(
                        icon: const Icon(Icons.favorite_border),
                        tooltip: 'Unfavorite selected',
                        onPressed: () => _bulkFavorite(false),
                      ),
                      IconButton(
                        icon: const Icon(Icons.drive_file_move_outlined),
                        tooltip: 'Move selected',
                        onPressed: _bulkMove,
                      ),
                      IconButton(
                        icon: const Icon(Icons.create_new_folder_outlined),
                        tooltip: 'Create album and move',
                        onPressed: _createAlbumAndMove,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Move to trash',
                        onPressed: _bulkTrash,
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            _GalleryPinchPeriodListener(
              enabled: !inSelectionMode,
              onPinchZoomIn: _handlePinchZoomIn,
              onPinchZoomOut: _handlePinchZoomOut,
              child: _buildBody(theme, motion),
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
                      heroTag: 'gallery_search',
                      tooltip: 'Search photos and videos',
                      onPressed: _openSearch,
                      child: const Icon(Icons.search),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, AppMotion motion) {
    if (_error != null && _items.isEmpty) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'Could not load gallery',
        message: _error,
      );
    }

    if (_items.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty) {
      return const EmptyState(
        icon: Icons.photo_library_outlined,
        title: 'No media yet',
        message: 'Sync your library to see photos and videos here.',
      );
    }

    final groups = _groupMedia(items: _items, period: _period);
    final navPadding = FloatingNavInsets.scrollPadding(context);
    final columns = _columnCount(context);
    final loadingMore = _loading && _hasMore;
    final inSelectionMode = _inSelectionMode;

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

  int _columnCount(BuildContext context) {
    return _period.crossAxisCountForWidth(MediaQuery.sizeOf(context).width);
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
            heroTag: mediaHeroTag(item.id),
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
