import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/app/router.dart';
import 'package:social_gallery/domain/models/folder_info.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/shared/widgets/empty_state.dart';
import 'package:social_gallery/shared/widgets/folder_avatar.dart';
import 'package:social_gallery/core/animation/app_motion.dart';
import 'package:social_gallery/data/repositories/media_repository.dart';
import 'package:social_gallery/shared/navigation/tab_scroll_to_top.dart';
import 'package:social_gallery/core/auth/folder_access.dart';
import 'package:social_gallery/shared/widgets/explore_mosaic_grid.dart';
import 'package:social_gallery/shared/widgets/media_grid.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/shared/widgets/folder_picker_sheet.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_page_header.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  static const _loadMoreThresholdPx = 400.0;

  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final List<MediaItem> _items = [];
  List<FolderInfo> _folderSuggestions = [];
  int _page = 0;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;
  final Set<int> _selectedIds = {};

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

    if (confirmed == true) {
      final repo = ref.read(mediaRepositoryProvider);
      final items = await _selectedItems();
      await repo.trashMedia(items);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Moved ${items.length} item(s) to trash')),
        );
      }
      setState(_selectedIds.clear);
      await _loadPage(refresh: true);
    }
  }

  Future<void> _bulkMove() async {
    final folders = await ref.read(folderRepositoryProvider).watchAll().first;
    if (!mounted) return;

    final targetPath = await showFolderPickerSheet(
      context: context,
      ref: ref,
      folders: folders,
    );

    if (targetPath != null) {
      final repo = ref.read(mediaRepositoryProvider);
      final items = await _selectedItems();
      await repo.moveMedia(items, targetPath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Moved ${items.length} item(s)')),
        );
      }
      setState(_selectedIds.clear);
      await _loadPage(refresh: true);
    }
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Created "$albumName" and moved ${items.length} item(s)'
                : 'Could not create album. Check storage access.',
          ),
        ),
      );
    }
    setState(_selectedIds.clear);
    await _loadPage(refresh: true);
  }

  Future<void> _bulkFavorite(bool favorite) async {
    final repo = ref.read(mediaRepositoryProvider);
    for (final id in _selectedIds) {
      await repo.setFavorite(id, favorite);
    }
    setState(() {
      _selectedIds.clear();
    });
    await _loadPage(refresh: true);
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);
    _scrollController.addListener(_onScroll);
    _loadPage();
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

  void _onSearchTextChanged() {
    if (_searchController.text.trim().isEmpty &&
        _folderSuggestions.isNotEmpty) {
      setState(() => _folderSuggestions = []);
    }
  }

  void _clearFolderSuggestions() {
    setState(() => _folderSuggestions = []);
  }

  Future<void> _openFolderProfile(FolderInfo folder) async {
    final ok = await ensureFolderUnlocked(ref: ref, folder: folder);
    if (!ok || !mounted) return;

    _clearFolderSuggestions();
    _searchController.clear();
    FocusManager.instance.primaryFocus?.unfocus();
    await context.push(folderProfileLocation(folder.path));
    if (!mounted) return;
    _clearFolderSuggestions();
    await _loadPage(refresh: true);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    super.dispose();
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

    final pageToLoad = refresh ? 0 : _page;

    try {
      final repo = ref.read(mediaRepositoryProvider);
      final items = await repo.searchExplorePage(
        _searchController.text,
        pageToLoad,
      );
      if (!mounted) return;
      setState(() {
        if (refresh) _items.clear();
        _items.addAll(items);
        _hasMore = items.length >= MediaRepository.pageSize;
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

  Future<void> _onSearchChanged() async {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      final folders = await ref
          .read(folderRepositoryProvider)
          .searchFolders(query);
      setState(() => _folderSuggestions = folders);
    } else {
      setState(() => _folderSuggestions = []);
    }
    await _loadPage(refresh: true);
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

    return Scaffold(
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
                    onPressed: () => setState(() => _selectedIds.clear()),
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
      body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!inSelectionMode) ...[
              const OneUiPageHeader(title: 'Explore'),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  OneUiSpacing.pageHorizontal,
                  0,
                  OneUiSpacing.pageHorizontal,
                  OneUiSpacing.sm,
                ),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Search photos and videos',
                  leading: const Icon(Icons.search, size: 20),
                  elevation: WidgetStateProperty.all(0),
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onChanged: (_) => _onSearchChanged(),
                ),
              ),
              if (_folderSuggestions.isNotEmpty)
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
                              : folder.coverImageUri,
                          locked: folder.isLockedAccount,
                        ),
                        label: Text(folder.name),
                        onPressed: () => _openFolderProfile(folder),
                      );
                    },
                  ),
                ),
            ],
            Expanded(child: _buildGrid()),
          ],
      ),
    );
  }

  Widget _buildGrid() {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return EmptyState(
        title: 'Could not load library',
        message: _error,
        icon: Icons.error_outline,
      );
    }
    if (_items.isEmpty) {
      return const EmptyState(
        title: 'No media found',
        message: 'Try a different search or add folders to Home Feed.',
      );
    }
    final loadingMore = _loading && _items.isNotEmpty;

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
            showLoadingFooter: loadingMore && _hasMore,
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
      onRefresh: () => _loadPage(refresh: true),
      child: grid,
    );
  }
}
