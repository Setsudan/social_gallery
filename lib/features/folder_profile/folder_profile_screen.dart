import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/auth/folder_unlock_store.dart';
import 'package:social_gallery/app/router.dart';
import 'package:social_gallery/core/utils/haptics.dart';
import 'package:social_gallery/domain/models/folder_info.dart';
import 'package:social_gallery/domain/models/follow_status.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/shared/widgets/empty_state.dart';
import 'package:social_gallery/shared/widgets/folder_avatar.dart';
import 'package:social_gallery/shared/widgets/folder_lock_gate.dart';
import 'package:social_gallery/shared/widgets/folder_picker_sheet.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/shared/widgets/media_grid.dart';

class FolderProfileScreen extends ConsumerStatefulWidget {
  const FolderProfileScreen({super.key, required this.folderPath});

  final String folderPath;

  @override
  ConsumerState<FolderProfileScreen> createState() =>
      _FolderProfileScreenState();
}

class _FolderProfileScreenState extends ConsumerState<FolderProfileScreen> {
  FolderUnlockStore? _unlockStore;
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
      excludePaths: [widget.folderPath],
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _unlockStore = ref.read(folderUnlockStoreProvider);
  }

  @override
  void dispose() {
    _unlockStore?.lock(widget.folderPath);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final folderAsync = ref.watch(folderProvider(widget.folderPath));
    final inSelectionMode = _selectedIds.isNotEmpty;

    return folderAsync.when(
      data: (folder) {
        if (folder == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Folder')),
            body: const EmptyState(title: 'Folder not found'),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: inSelectionMode
                ? Text('${_selectedIds.length} selected')
                : const Text(''),
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
                : null,
          ),
          body: Column(
            children: [
              _header(folder),
              Expanded(
                child: FolderLockGate(
                  folder: folder,
                  builder: (context) => ref
                      .watch(folderMediaProvider(folder.path))
                      .when(
                        data: (items) {
                          if (items.isEmpty) {
                            return const EmptyState(title: 'No media');
                          }
                          return MediaGrid(
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
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) =>
                            EmptyState(title: 'Error', message: e.toString()),
                      ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
    );
  }

  Widget _header(FolderInfo folder) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        OneUiSpacing.pageHorizontal,
        OneUiSpacing.md,
        OneUiSpacing.pageHorizontal,
        OneUiSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FolderAvatar(
            name: folder.name,
            size: 72,
            coverUri: folder.isLockedAccount ? null : folder.coverImageUri,
            locked: folder.isLockedAccount,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  folder.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text('${folder.mediaCount} items'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _editBio(folder),
                  child: Text(
                    folder.biography?.isNotEmpty == true
                        ? folder.biography!
                        : 'Add biography',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showFollowDialog(folder),
          ),
        ],
      ),
    );
  }

  Future<void> _editBio(FolderInfo folder) async {
    final controller = TextEditingController(text: folder.biography ?? '');

    final saved = await showDialog<String>(
      context: context,

      builder: (context) => AlertDialog(
        title: const Text('Biography'),

        content: TextField(controller: controller, maxLines: 4),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),

            child: const Text('Cancel'),
          ),

          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),

            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != null) {
      await ref
          .read(folderRepositoryProvider)
          .updateFollowStatus(
            folder.path,

            folder.followStatus,

            isBiometricLocked: folder.isBiometricLocked,

            biography: saved,
          );
    }
  }

  Future<void> _showFollowDialog(FolderInfo folder) async {
    var choice = _visibilityChoice(
      folder.followStatus,
      folder.isBiometricLocked,
    );

    await showDialog<void>(
      context: context,

      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Folder visibility'),

              content: Column(
                mainAxisSize: MainAxisSize.min,

                children: _FolderVisibilityOption.values
                    .map(
                      (option) => ListTile(
                        title: Text(option.label),

                        leading: Radio<_FolderVisibilityOption>(
                          value: option,

                          groupValue: choice,

                          onChanged: (v) => setDialogState(() => choice = v!),
                        ),

                        onTap: () => setDialogState(() => choice = option),
                      ),
                    )
                    .toList(),
              ),

              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),

                  child: const Text('Cancel'),
                ),

                FilledButton(
                  onPressed: () async {
                    await ref
                        .read(folderRepositoryProvider)
                        .updateFollowStatus(
                          folder.path,

                          choice.status,

                          isBiometricLocked: choice.locked,
                        );

                    if (choice.locked) {
                      ref.read(folderUnlockStoreProvider).lock(folder.path);
                    }

                    ref.invalidate(folderProvider(folder.path));

                    if (context.mounted) Navigator.pop(context);
                  },

                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  _FolderVisibilityOption _visibilityChoice(FollowStatus status, bool locked) {
    if (status == FollowStatus.homeFeed) {
      return _FolderVisibilityOption.homeFeed;
    }

    if (status == FollowStatus.unfollowed) {
      return _FolderVisibilityOption.hidden;
    }

    return locked
        ? _FolderVisibilityOption.accountLocked
        : _FolderVisibilityOption.accountOnly;
  }
}

enum _FolderVisibilityOption {
  homeFeed('Home Feed', FollowStatus.homeFeed, false),

  accountOnly('Account only', FollowStatus.accountOnly, false),

  accountLocked('Account only (locked)', FollowStatus.accountOnly, true),

  hidden('Hidden', FollowStatus.unfollowed, false);

  const _FolderVisibilityOption(this.label, this.status, this.locked);

  final String label;

  final FollowStatus status;

  final bool locked;
}

final folderProvider = StreamProvider.family<FolderInfo?, String>(
  (ref, path) => ref.watch(folderRepositoryProvider).watchFolder(path),
);
