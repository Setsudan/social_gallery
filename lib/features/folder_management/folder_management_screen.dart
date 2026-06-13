import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/app/router.dart';
import 'package:social_gallery/core/utils/haptics.dart';
import 'package:social_gallery/domain/models/folder_info.dart';
import 'package:social_gallery/domain/models/follow_status.dart';
import 'package:social_gallery/core/animation/app_motion.dart';
import 'package:social_gallery/shared/widgets/empty_state.dart';
import 'package:social_gallery/shared/widgets/folder_avatar.dart';
import 'package:social_gallery/shared/widgets/motion/selection_chrome.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/shared/widgets/motion/staggered_entrance.dart';
import 'package:social_gallery/shared/pagination/paginated_list_notifier.dart';

class FolderManagementScreen extends ConsumerStatefulWidget {
  const FolderManagementScreen({super.key});

  @override
  ConsumerState<FolderManagementScreen> createState() =>
      _FolderManagementScreenState();
}

class _FolderManagementScreenState
    extends ConsumerState<FolderManagementScreen> {
  final Set<String> _selected = {};

  bool get _selectionMode => _selected.isNotEmpty;

  void _toggleSelect(String path) {
    AppHaptics.medium();
    setState(() {
      if (_selected.contains(path)) {
        _selected.remove(path);
      } else {
        _selected.add(path);
      }
    });
  }

  Future<void> _bulkSet(FollowStatus status) async {
    AppHaptics.light();
    await ref
        .read(folderRepositoryProvider)
        .bulkUpdateFollowStatus(_selected.toList(), status);
    setState(_selected.clear);
    ref.invalidate(allFoldersProvider);
    refreshFeedProviders(ref);
    AppHaptics.success();
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

  @override
  Widget build(BuildContext context) {
    final foldersAsync = ref.watch(allFoldersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: _selectionMode ? Text('${_selected.length} selected') : null,
        leading: IconButton(
          icon: Icon(_selectionMode ? Icons.close : Icons.arrow_back),
          onPressed: () {
            AppHaptics.light();
            if (_selectionMode) {
              setState(_selected.clear);
            } else {
              context.pop();
            }
          },
        ),
      ),
      bottomNavigationBar: AnimatedSelectionBar(
        visible: _selectionMode,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _bulkSet(FollowStatus.homeFeed),
                    child: const Text('Home Feed'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _bulkSet(FollowStatus.accountOnly),
                    child: const Text('Account'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _bulkSet(FollowStatus.unfollowed),
                    child: const Text('Hidden'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: foldersAsync.when(
        data: (folders) {
          if (folders.isEmpty) {
            return const Center(child: Text('No folders found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: OneUiSpacing.xl),
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              return StaggeredEntrance(
                index: index,
                playOnceKey: 'folder_${folder.path}',
                child: _folderTile(folder, theme),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          title: 'Could not load folders',
          message: e.toString(),
          icon: Icons.error_outline,
        ),
      ),
    );
  }

  Widget _folderTile(FolderInfo folder, ThemeData theme) {
    final isSelected = _selected.contains(folder.path);
    final motion = AppMotion.of(context, ref);

    return AnimatedContainer(
      duration: motion.fadeFast,
      curve: motion.enterCurve,
      margin: const EdgeInsets.symmetric(
        horizontal: OneUiSpacing.pageHorizontal,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(OneUiRadii.card),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OneUiRadii.card),
          side: BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: FolderAvatar(
                  name: folder.name,
                  coverUri: folder.isLockedAccount
                      ? null
                      : folder.displayCoverUri,
                  locked: folder.isLockedAccount,
                ),
                title: Text(
                  folder.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${folder.mediaCount} items'),
                trailing: PopupMenuButton<_FolderVisibilityOption>(
                  initialValue: _visibilityChoice(
                    folder.followStatus,
                    folder.isBiometricLocked,
                  ),
                  child: _statusChip(folder, theme),
                  onSelected: (option) async {
                    AppHaptics.medium();
                    await ref
                        .read(folderRepositoryProvider)
                        .updateFollowStatus(
                          folder.path,
                          option.status,
                          isBiometricLocked: option.locked,
                        );
                    if (option.locked) {
                      ref.read(folderUnlockStoreProvider).lock(folder.path);
                    }
                    ref.invalidate(allFoldersProvider);
                    refreshFeedProviders(ref);
                  },
                  itemBuilder: (context) => _FolderVisibilityOption.values
                      .map(
                        (opt) => PopupMenuItem<_FolderVisibilityOption>(
                          value: opt,
                          child: Text(opt.label),
                        ),
                      )
                      .toList(),
                ),
                onLongPress: () => _toggleSelect(folder.path),
                onTap: () {
                  if (_selectionMode) {
                    _toggleSelect(folder.path);
                  } else {
                    AppHaptics.light();
                    context.push(folderProfileLocation(folder.path));
                  }
                },
              ),
              const Divider(height: 16),
              Row(
                children: [
                  const Icon(Icons.history_toggle_off, size: 16),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Show in Stories',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  Switch.adaptive(
                    value: folder.showInStories,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (val) async {
                      AppHaptics.medium();
                      await ref
                          .read(folderRepositoryProvider)
                          .updateFolderStories(folder.path, val);
                      ref.invalidate(allFoldersProvider);
                      refreshFeedProviders(ref);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    folder.isBiometricLocked ? Icons.lock : Icons.lock_open,
                    size: 16,
                    color: folder.isBiometricLocked
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text('Secure Lock', style: TextStyle(fontSize: 12)),
                  ),
                  Switch.adaptive(
                    value: folder.isBiometricLocked,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (val) async {
                      AppHaptics.medium();
                      await ref
                          .read(folderRepositoryProvider)
                          .updateFollowStatus(
                            folder.path,
                            folder.followStatus,
                            isBiometricLocked: val,
                          );
                      if (val) {
                        ref.read(folderUnlockStoreProvider).lock(folder.path);
                      }
                      ref.invalidate(allFoldersProvider);
                      refreshFeedProviders(ref);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(FolderInfo folder, ThemeData theme) {
    late String label;
    late Color bg;
    late Color fg;

    switch (folder.followStatus) {
      case FollowStatus.homeFeed:
        label = 'Home Feed';
        bg = theme.colorScheme.primaryContainer;
        fg = theme.colorScheme.onPrimaryContainer;
      case FollowStatus.accountOnly:
        label = folder.isBiometricLocked ? 'Locked' : 'Account';
        bg = theme.colorScheme.secondaryContainer;
        fg = theme.colorScheme.onSecondaryContainer;
      case FollowStatus.unfollowed:
        label = 'Hidden';
        bg = theme.colorScheme.errorContainer;
        fg = theme.colorScheme.onErrorContainer;
    }

    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.arrow_drop_down, size: 14, color: fg),
        ],
      ),
      backgroundColor: bg,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
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
