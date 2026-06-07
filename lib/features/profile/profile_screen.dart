import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/app/router.dart';
import 'package:social_gallery/core/utils/haptics.dart';
import 'package:social_gallery/domain/models/folder_info.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/shared/widgets/empty_state.dart';
import 'package:social_gallery/shared/widgets/folder_lock_gate.dart';
import 'package:social_gallery/core/animation/modal_sheet.dart';
import 'package:social_gallery/shared/widgets/folder_picker_sheet.dart';
import 'package:social_gallery/shared/widgets/media_grid.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_page_header.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _scrollController = ScrollController();
  final Set<int> _selectedIds = {};

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

  Future<void> _bulkDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to Trash'),
        content: Text(
          'Are you sure you want to move ${_selectedIds.length} items to trash? They can be restored in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Move to Trash'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      AppHaptics.light();
      final repo = ref.read(mediaRepositoryProvider);
      final itemsToTrash = <MediaItem>[];
      for (final id in _selectedIds) {
        final item = await repo.getMediaById(id);
        if (item != null) itemsToTrash.add(item);
      }

      await repo.trashMedia(itemsToTrash);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Moved ${itemsToTrash.length} item(s) to trash'),
          ),
        );
      }
      setState(() {
        _selectedIds.clear();
      });
      AppHaptics.success();
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
      AppHaptics.light();
      final repo = ref.read(mediaRepositoryProvider);
      final itemsToMove = <MediaItem>[];
      for (final id in _selectedIds) {
        final item = await repo.getMediaById(id);
        if (item != null) itemsToMove.add(item);
      }

      await repo.moveMedia(itemsToMove, targetPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully moved ${itemsToMove.length} items'),
          ),
        );
      }
      setState(() {
        _selectedIds.clear();
      });
      AppHaptics.success();
    }
  }

  Future<void> _bulkFavorite(bool favorite) async {
    AppHaptics.light();
    final repo = ref.read(mediaRepositoryProvider);
    for (final id in _selectedIds) {
      await repo.setFavorite(id, favorite);
    }
    setState(() {
      _selectedIds.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureActiveFolder());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _ensureActiveFolder() async {
    var active = ref.read(activeProfileFolderProvider);
    if (active != null) return;

    final prefs = ref.read(preferencesRepositoryProvider);
    active = prefs.activeProfileFolderPath;

    if (active == null) {
      final folders = await ref.read(folderRepositoryProvider).watchAll().first;
      if (folders.isNotEmpty) {
        active = folders.first.path;
        await prefs.setActiveProfileFolderPath(active);
      }
    }

    if (active != null) {
      ref.read(activeProfileFolderProvider.notifier).state = active;
    }
  }

  Future<void> _showStorageSettings() async {
    final storage = ref.read(storageAccessServiceProvider);
    final granted = await storage.hasAllFilesAccess();
    if (!mounted) return;

    await showAppModalBottomSheet<void>(
      context: context,
      ref: ref,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'All files access',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  granted
                      ? 'Granted. You can move and delete items across albums.'
                      : 'Required on Android 11+ to move or delete items between albums.',
                ),
                const SizedBox(height: 16),
                if (!granted)
                  FilledButton(
                    onPressed: () async {
                      await storage.requestAllFilesAccess();
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Grant in settings'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickFolder(List<FolderInfo> folders) async {
    final selected = await showFolderPickerSheet(
      context: context,
      ref: ref,
      folders: folders,
      title: 'Select folder',
    );

    if (selected != null) {
      await ref
          .read(preferencesRepositoryProvider)
          .setActiveProfileFolderPath(selected);
      ref.read(activeProfileFolderProvider.notifier).state = selected;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activePath = ref.watch(activeProfileFolderProvider);
    final foldersAsync = ref.watch(allFoldersProvider);
    final inSelectionMode = _selectedIds.isNotEmpty;
    final profileTitle = foldersAsync.maybeWhen(
      data: (folders) => folders
          .where((f) => f.path == activePath)
          .map((f) => f.name)
          .firstOrNull,
      orElse: () => null,
    );

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: inSelectionMode ? Text('${_selectedIds.length} selected') : null,
        leading: inSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selectedIds.clear()),
              )
            : null,
        actions: inSelectionMode
            ? [
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
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Trash selected',
                  onPressed: _bulkDelete,
                ),
              ]
            : [
                if (Platform.isAndroid)
                  IconButton(
                    icon: const Icon(Icons.folder_shared_outlined),
                    tooltip: 'File access',
                    onPressed: _showStorageSettings,
                  ),
                IconButton(
                  icon: const Icon(Icons.swap_horiz),
                  onPressed: foldersAsync.maybeWhen(
                    data: (folders) =>
                        folders.isEmpty ? null : () => _pickFolder(folders),
                    orElse: () => null,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.person_outline),
                  onPressed: activePath == null
                      ? null
                      : () => context.push(folderProfileLocation(activePath)),
                ),
                IconButton(
                  icon: const Icon(Icons.folder_open_outlined),
                  tooltip: 'Manage content',
                  onPressed: () {
                    AppHaptics.light();
                    context.push('/folder_management');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'Settings',
                  onPressed: () {
                    AppHaptics.light();
                    context.push('/settings');
                  },
                ),
              ],
      ),
      body: activePath == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!inSelectionMode) const OneUiPageHeader(title: 'Profile'),
                const Expanded(
                  child: EmptyState(
                    title: 'No folder selected',
                    message: 'Sync your library or pick a folder.',
                  ),
                ),
              ],
            )
          : foldersAsync.when(
              data: (folders) {
                final folder = folders
                    .where((f) => f.path == activePath)
                    .firstOrNull;
                if (folder == null) {
                  return const EmptyState(title: 'Folder not found');
                }
                return FolderLockGate(
                  folder: folder,
                  builder: (context) => ref
                      .watch(folderMediaProvider(activePath))
                      .when(
                        data: (items) {
                          if (items.isEmpty) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (!inSelectionMode)
                                  OneUiPageHeader(
                                    title: profileTitle ?? 'Profile',
                                  ),
                                const Expanded(
                                  child: EmptyState(
                                    title: 'No media in this folder',
                                  ),
                                ),
                              ],
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (!inSelectionMode)
                                OneUiPageHeader(
                                  title: profileTitle ?? 'Profile',
                                ),
                              Expanded(
                                child: MediaGrid(
                                  controller: _scrollController,
                                  items: items,
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
                                ),
                              ),
                            ],
                          );
                        },
                        loading: () => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!inSelectionMode)
                              OneUiPageHeader(title: profileTitle ?? 'Profile'),
                            const Expanded(
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          ],
                        ),
                        error: (e, _) => EmptyState(
                          title: 'Could not load folder',
                          message: e.toString(),
                        ),
                      ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => EmptyState(
                title: 'Could not load folders',
                message: e.toString(),
              ),
            ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
