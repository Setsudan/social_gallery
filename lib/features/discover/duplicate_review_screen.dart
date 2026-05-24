import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/domain/models/duplicate_group.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/shared/dialogs/storage_access_dialog.dart';
import 'package:social_gallery/shared/widgets/media_thumbnail.dart';

class DuplicateReviewScreen extends ConsumerStatefulWidget {
  const DuplicateReviewScreen({super.key, required this.groupKey});

  final String groupKey;

  @override
  ConsumerState<DuplicateReviewScreen> createState() =>
      _DuplicateReviewScreenState();
}

class _DuplicateReviewScreenState extends ConsumerState<DuplicateReviewScreen> {
  DuplicateGroup? _group;
  late Set<int> _selectedIds;
  MediaItem? _keeper;
  bool _loading = true;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final candidates =
        await ref.read(mediaRepositoryProvider).getPotentialDuplicates();
    final groups = ref.read(findDuplicateGroupsProvider)(candidates);
    final group = groups.where((g) => g.key == widget.groupKey).firstOrNull;
    if (group == null) {
      setState(() => _loading = false);
      return;
    }
    final keeper = ref.read(suggestKeepBestProvider)(group.items);
    final toRemove = ref.read(suggestKeepBestProvider).idsToRemove(group.items);
    setState(() {
      _group = group;
      _keeper = keeper;
      _selectedIds = toRemove;
      _loading = false;
    });
  }

  Future<void> _confirmDelete() async {
    if (_group == null || _selectedIds.isEmpty) return;

    final hasAccess = await ensureAllFilesAccess(context, ref);
    if (!hasAccess || !mounted) return;

    setState(() => _deleting = true);
    final toDelete =
        _group!.items.where((m) => _selectedIds.contains(m.id)).toList();
    final ok = await ref.read(mediaRepositoryProvider).deleteFromDevice(toDelete);
    if (!mounted) return;
    setState(() => _deleting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Removed ${toDelete.length} duplicate(s).'
              : 'Could not remove some items. Check permissions.',
        ),
      ),
    );
    if (ok) {
      final router = GoRouter.of(context);
      router.pop();
      if (router.canPop()) {
        router.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review duplicates')),
        body: const Center(child: Text('Group not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review duplicates'),
        actions: [
          TextButton(
            onPressed: _selectedIds.isEmpty || _deleting ? null : _confirmDelete,
            child: _deleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Delete (${_selectedIds.length})'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Keep best is pre-selected. Tap items to change what will be removed.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _group!.items.length,
              itemBuilder: (context, index) {
                final media = _group!.items[index];
                final isKeeper = media.id == _keeper?.id;
                final selected = _selectedIds.contains(media.id);
                return GestureDetector(
                  onTap: () {
                    if (isKeeper) return;
                    setState(() {
                      if (selected) {
                        _selectedIds.remove(media.id);
                      } else {
                        _selectedIds.add(media.id);
                      }
                    });
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MediaThumbnail(
                        assetId: media.uri,
                        showVideoBadge: media.isVideo,
                      ),
                      if (isKeeper)
                        Container(
                          color: Colors.black26,
                          child: const Center(
                            child: Chip(
                              label: Text('Keep'),
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ),
                      if (selected && !isKeeper)
                        Container(
                          color: Colors.red.withValues(alpha: 0.35),
                          child: const Center(
                            child: Icon(Icons.delete_outline, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
