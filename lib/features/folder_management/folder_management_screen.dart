import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/app/router.dart';
import 'package:social_gallery/domain/models/folder_info.dart';
import 'package:social_gallery/domain/models/follow_status.dart';
import 'package:social_gallery/shared/widgets/folder_avatar.dart';

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
    setState(() {
      if (_selected.contains(path)) {
        _selected.remove(path);
      } else {
        _selected.add(path);
      }
    });
  }

  Future<void> _bulkSet(FollowStatus status) async {
    await ref
        .read(folderRepositoryProvider)
        .bulkUpdateFollowStatus(_selected.toList(), status);
    setState(_selected.clear);
  }

  @override
  Widget build(BuildContext context) {
    final foldersAsync = ref.watch(allFoldersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectionMode
              ? '${_selected.length} selected'
              : 'Manage Content',
        ),
        leading: IconButton(
          icon: Icon(_selectionMode ? Icons.close : Icons.arrow_back),
          onPressed: () {
            if (_selectionMode) {
              setState(_selected.clear);
            } else {
              context.pop();
            }
          },
        ),
      ),
      bottomNavigationBar: _selectionMode
          ? SafeArea(
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
            )
          : null,
      body: foldersAsync.when(
        data: (folders) {
          final home = folders
              .where((f) => f.followStatus == FollowStatus.homeFeed)
              .toList();
          final account = folders
              .where((f) => f.followStatus == FollowStatus.accountOnly)
              .toList();
          final hidden = folders
              .where((f) => f.followStatus == FollowStatus.unfollowed)
              .toList();

          return ListView(
            children: [
              _section(context, 'Home Feed', home),
              _section(context, 'Account Only', account),
              _section(context, 'Hidden', hidden),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<FolderInfo> folders) {
    if (folders.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        ...folders.map((folder) => _folderTile(folder)),
      ],
    );
  }

  Widget _folderTile(FolderInfo folder) {
    final selected = _selected.contains(folder.path);
    return ListTile(
      leading: FolderAvatar(
        name: folder.name,
        coverUri: folder.isLockedAccount ? null : folder.coverImageUri,
        locked: folder.isLockedAccount,
      ),
      title: Text(folder.name),
      subtitle: Text('${folder.mediaCount} items'),
      trailing: _statusChip(folder),
      selected: selected,
      onTap: () {
        if (_selectionMode) {
          _toggleSelect(folder.path);
        } else {
          context.push(folderProfileLocation(folder.path));
        }
      },
      onLongPress: () => _toggleSelect(folder.path),
    );
  }

  Widget _statusChip(FolderInfo folder) {
    final theme = Theme.of(context);
    late String label;
    late Color bg;
    late Color fg;

    switch (folder.followStatus) {
      case FollowStatus.homeFeed:
        label = 'Feed';
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
      label: Text(label, style: TextStyle(color: fg, fontSize: 12)),
      backgroundColor: bg,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
