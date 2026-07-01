import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/app/router.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
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
import 'package:social_gallery/l10n/app_localizations.dart';

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
    final l10n = context.l10n;
    final foldersAsync = ref.watch(allFoldersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: _selectionMode
            ? Text(l10n.selectionCount(_selected.length))
            : null,
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
                    child: Text(l10n.folderVisibilityHomeFeed),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _bulkSet(FollowStatus.accountOnly),
                    child: Text(l10n.folderVisibilityAccount),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _bulkSet(FollowStatus.unfollowed),
                    child: Text(l10n.folderVisibilityHidden),
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
            return Center(child: Text(l10n.folderManagementNoFolders));
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: OneUiSpacing.xl),
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              return StaggeredEntrance(
                index: index,
                playOnceKey: 'folder_${folder.path}',
                child: _folderTile(folder, theme, l10n),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          title: l10n.profileErrorLoadFolders,
          message: e.toString(),
          icon: Icons.error_outline,
        ),
      ),
    );
  }

  Widget _folderTile(FolderInfo folder, ThemeData theme, AppLocalizations l10n) {
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
                subtitle: Text(l10n.folderItemCount(folder.mediaCount)),
                trailing: PopupMenuButton<_FolderVisibilityOption>(
                  initialValue: _visibilityChoice(
                    folder.followStatus,
                    folder.isBiometricLocked,
                  ),
                  child: _statusChip(folder, theme, l10n),
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
                          child: Text(opt.menuLabel(l10n)),
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
                  Expanded(
                    child: Text(
                      l10n.folderShowInStories,
                      style: const TextStyle(fontSize: 12),
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
                  Expanded(
                    child: Text(
                      l10n.folderSecureLock,
                      style: const TextStyle(fontSize: 12),
                    ),
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

  Widget _statusChip(
    FolderInfo folder,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final option = _visibilityChoice(
      folder.followStatus,
      folder.isBiometricLocked,
    );
    final label = option.chipLabel(l10n);
    late Color bg;
    late Color fg;

    switch (folder.followStatus) {
      case FollowStatus.homeFeed:
        bg = theme.colorScheme.primaryContainer;
        fg = theme.colorScheme.onPrimaryContainer;
      case FollowStatus.accountOnly:
        bg = theme.colorScheme.secondaryContainer;
        fg = theme.colorScheme.onSecondaryContainer;
      case FollowStatus.unfollowed:
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
  homeFeed(FollowStatus.homeFeed, false),
  accountOnly(FollowStatus.accountOnly, false),
  accountLocked(FollowStatus.accountOnly, true),
  hidden(FollowStatus.unfollowed, false);

  const _FolderVisibilityOption(this.status, this.locked);

  final FollowStatus status;
  final bool locked;

  String menuLabel(AppLocalizations l10n) => switch (this) {
        homeFeed => l10n.folderVisibilityHomeFeed,
        accountOnly => l10n.folderVisibilityAccountOnly,
        accountLocked => l10n.folderVisibilityAccountLocked,
        hidden => l10n.folderVisibilityHidden,
      };

  String chipLabel(AppLocalizations l10n) => switch (this) {
        homeFeed => l10n.folderVisibilityHomeFeed,
        accountOnly => l10n.folderVisibilityAccount,
        accountLocked => l10n.folderVisibilityLock,
        hidden => l10n.folderVisibilityHidden,
      };
}
