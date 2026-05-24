import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/app/router.dart';
import 'package:social_gallery/domain/models/folder_info.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/shared/widgets/empty_state.dart';
import 'package:social_gallery/shared/widgets/folder_avatar.dart';
import 'package:social_gallery/shared/widgets/explore_mosaic_grid.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _searchController = TextEditingController();
  final List<MediaItem> _items = [];
  List<FolderInfo> _folderSuggestions = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);
    _load();
  }

  void _onSearchTextChanged() {
    if (_searchController.text.trim().isEmpty && _folderSuggestions.isNotEmpty) {
      setState(() => _folderSuggestions = []);
    }
  }

  void _clearFolderSuggestions() {
    setState(() => _folderSuggestions = []);
  }

  Future<void> _openFolderProfile(String folderPath) async {
    _clearFolderSuggestions();
    _searchController.clear();
    FocusManager.instance.primaryFocus?.unfocus();
    await context.push(folderProfileLocation(folderPath));
    if (!mounted) return;
    _clearFolderSuggestions();
    await _load();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(mediaRepositoryProvider);
      final items = await repo.searchExplore(_searchController.text);
      setState(() {
        _items
          ..clear()
          ..addAll(items);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _onSearchChanged() async {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      final folders =
          await ref.read(folderRepositoryProvider).searchFolders(query);
      setState(() => _folderSuggestions = folders);
    } else {
      setState(() => _folderSuggestions = []);
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final folder = _folderSuggestions[index];
                    return ActionChip(
                      avatar: FolderAvatar(
                        name: folder.name,
                        size: 28,
                        coverUri: folder.coverImageUri,
                        locked: folder.isLockedAccount,
                      ),
                      label: Text(folder.name),
                      onPressed: () => _openFolderProfile(folder.path),
                    );
                  },
                ),
              ),
            Expanded(child: _buildGrid()),
          ],
        ),
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
    return RefreshIndicator(
      onRefresh: _load,
      child: ExploreMosaicGrid(
        items: _items,
        onTap: (item) => context.push(
          mediaViewerLocation(
            item.uri,
            mediaId: item.id,
            favorite: item.isFavorite,
          ),
        ),
      ),
    );
  }
}
