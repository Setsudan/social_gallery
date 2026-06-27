import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/layout/responsive_grid.dart';
import 'package:social_gallery/domain/models/duplicate_group.dart';
import 'package:social_gallery/features/discover/discover_providers.dart';
import 'package:social_gallery/shared/dialogs/storage_access_dialog.dart';
import 'package:social_gallery/shared/widgets/empty_state.dart';
import 'package:social_gallery/shared/widgets/media_thumbnail.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_subpage_scaffold.dart';

class DuplicateReviewScreen extends ConsumerStatefulWidget {
  const DuplicateReviewScreen({super.key, required this.groupKey});

  final String groupKey;

  @override
  ConsumerState<DuplicateReviewScreen> createState() =>
      _DuplicateReviewScreenState();
}

class _DuplicateReviewScreenState extends ConsumerState<DuplicateReviewScreen> {
  Set<int>? _selectedIds;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(duplicateScanControllerProvider.notifier).ensureStarted();
    });
  }

  DuplicateGroup? _findGroup(List<DuplicateGroup> groups) {
    return groups.where((g) => g.key == widget.groupKey).firstOrNull;
  }

  void _initSelection(DuplicateGroup group) {
    if (_selectedIds != null) return;
    _selectedIds = ref.read(suggestKeepBestProvider).idsToRemove(group.items);
  }

  Future<void> _confirmDelete(DuplicateGroup group) async {
    final selectedIds = _selectedIds;
    if (selectedIds == null || selectedIds.isEmpty) return;

    final hasAccess = await ensureAllFilesAccess(context, ref);
    if (!hasAccess || !mounted) return;

    setState(() => _deleting = true);
    final toDelete =
        group.items.where((m) => selectedIds.contains(m.id)).toList();
    final ok = await ref
        .read(mediaRepositoryProvider)
        .deleteFromDevice(toDelete);
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
      ref.invalidate(duplicateScanControllerProvider);
      ref.invalidate(discoverHubProvider);
      final router = GoRouter.of(context);
      router.pop();
      if (router.canPop()) {
        router.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scan = ref.watch(duplicateScanControllerProvider);

    if (scan.error != null) {
      return OneUiSubpageScaffold(
        title: 'Review duplicates',
        error: scan.error,
        body: const SizedBox.shrink(),
      );
    }

    if (!scan.isComplete) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (scan.total > 0)
                  LinearProgressIndicator(value: scan.progress)
                else
                  const LinearProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  scan.total > 0
                      ? 'Analyzing ${scan.scanned} / ${scan.total} photos...'
                      : 'Preparing duplicate scan...',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final groups = scan.groups!;
    final group = _findGroup(groups);
        if (group == null) {
          return OneUiSubpageScaffold(
            title: 'Review duplicates',
            isEmpty: true,
            empty: const EmptyState(
              title: 'Group not found',
              icon: Icons.search_off,
            ),
            body: const SizedBox.shrink(),
          );
        }

        _initSelection(group);
        final selectedIds = _selectedIds!;
        final keeper = ref.read(suggestKeepBestProvider)(group.items);
        final columns = gridCrossAxisCountForWidth(
          MediaQuery.sizeOf(context).width,
        );

        return OneUiSubpageScaffold(
          title: 'Review duplicates',
          subtitle:
              'Keep best is pre-selected. Tap items to change what will be removed.',
          actions: [
            TextButton(
              onPressed: selectedIds.isEmpty || _deleting
                  ? null
                  : () => _confirmDelete(group),
              child: _deleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Delete (${selectedIds.length})'),
            ),
          ],
          body: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: group.items.length,
              itemBuilder: (context, index) {
                final media = group.items[index];
                final isKeeper = media.id == keeper.id;
                final selected = selectedIds.contains(media.id);
                return GestureDetector(
                  onTap: () {
                    if (isKeeper) return;
                    setState(() {
                      if (selected) {
                        selectedIds.remove(media.id);
                      } else {
                        selectedIds.add(media.id);
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
                            child: Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
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
