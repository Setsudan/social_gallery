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
import 'package:social_gallery/shared/media/media_bulk_actions.dart';
import 'package:social_gallery/shared/widgets/folder_picker_sheet.dart';
import 'package:social_gallery/shared/widgets/media_grid.dart';
import 'package:social_gallery/shared/widgets/media_selection_app_bar.dart';

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

  void _clearSelection() => setState(_selectedIds.clear);

  Future<void> _bulkDelete() => bulkTrash(
        ref,
        context,
        _selectedIds,
        onDone: _clearSelection,
        useHaptics: true,
      );

  Future<void> _bulkMove() => bulkMove(
        ref,
        context,
        _selectedIds,
        onDone: _clearSelection,
        useHaptics: true,
      );

  Future<void> _bulkFavorite(bool favorite) => bulkFavorite(
        ref,
        _selectedIds,
        favorite,
        onDone: _clearSelection,
        useHaptics: true,
      );

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

    final PreferredSizeWidget appBar = inSelectionMode
        ? MediaSelectionAppBar(
            selectedCount: _selectedIds.length,
            onCancel: _clearSelection,
            onFavorite: () => _bulkFavorite(true),
            onUnfavorite: () => _bulkFavorite(false),
            onMove: _bulkMove,
            onTrash: _bulkDelete,
          )
        : AppBar(
            actions: [
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
          );

    return Scaffold(
      extendBody: true,
      appBar: appBar,
      body: activePath == null
          ? const Expanded(
              child: EmptyState(
                    title: 'No folder selected',
                    message: 'Sync your library or pick a folder.',
                  ),
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
                            return const EmptyState(
                              title: 'No media in this folder',
                            );
                          }
                          return MediaGrid(
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
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(),
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
