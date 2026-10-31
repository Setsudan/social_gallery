import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/core/layout/responsive_grid.dart';
import 'package:social_gallery/domain/models/duplicate_group.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/domain/usecases/suggest_keep_best.dart';
import 'package:social_gallery/features/discover/discover_providers.dart';
import 'package:social_gallery/shared/dialogs/storage_access_dialog.dart';
import 'package:social_gallery/shared/pagination/paginated_list_notifier.dart';
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
  int? _keeperId;
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
    final suggestion = ref.read(suggestKeepBestProvider).suggestWithReason(group.items);
    _keeperId = suggestion.keeper.id;
    _selectedIds = group.items
        .where((m) => m.id != _keeperId)
        .map((m) => m.id)
        .toSet();
  }

  void _selectAsKeeper(MediaItem media, DuplicateGroup group) {
    setState(() {
      _keeperId = media.id;
      _selectedIds = group.items
          .where((m) => m.id != media.id)
          .map((m) => m.id)
          .toSet();
    });
  }

  Future<void> _confirmDelete(DuplicateGroup group) async {
    final selectedIds = _selectedIds;
    final keeperId = _keeperId;
    if (selectedIds == null || selectedIds.isEmpty || keeperId == null) return;

    final l10n = context.l10n;
    final keeper = group.items.firstWhere((m) => m.id == keeperId);
    final toDelete = group.items.where((m) => selectedIds.contains(m.id)).toList();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.duplicateDeleteConfirmTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.duplicateDeleteConfirmMessage(
              keeper.displayName,
              toDelete.length,
            )),
            const SizedBox(height: 16),
            Text(
              l10n.duplicateDeleteWarning,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.duplicateDeleteAction(toDelete.length)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final hasAccess = await ensureAllFilesAccess(context, ref);
    if (!hasAccess || !mounted) return;

    setState(() => _deleting = true);
    final ok = await ref
        .read(mediaRepositoryProvider)
        .deleteFromDevice(toDelete);
    if (!mounted) return;
    setState(() => _deleting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? l10n.snackbarDuplicatesRemoved(toDelete.length)
              : l10n.snackbarDuplicatesRemoveFailed,
        ),
      ),
    );
    if (ok) {
      refreshFeedProviders(ref);
      ref.invalidate(duplicateScanControllerProvider);
      ref.invalidate(discoverHubProvider);
      context.pop();
    }
  }

  String _keeperReasonText(BuildContext context, KeeperReason reason) {
    final l10n = context.l10n;
    return switch (reason) {
      KeeperReason.newest => l10n.duplicateReasonNewest,
      KeeperReason.largestFile => l10n.duplicateReasonLargestFile,
      KeeperReason.highestResolution => l10n.duplicateReasonHighestResolution,
      KeeperReason.first => l10n.duplicateReasonFirst,
    };
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final scan = ref.watch(duplicateScanControllerProvider);
    final l10n = context.l10n;

    if (scan.error != null) {
      return OneUiSubpageScaffold(
        title: l10n.duplicateReviewTitle,
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
                      ? l10n.duplicateScanProgress(scan.scanned, scan.total)
                      : l10n.duplicateScanPreparing,
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
        title: l10n.duplicateReviewTitle,
        isEmpty: true,
        empty: EmptyState(
          title: l10n.duplicateReviewGroupNotFound,
          icon: Icons.search_off,
        ),
        body: const SizedBox.shrink(),
      );
    }

    _initSelection(group);
    final selectedIds = _selectedIds!;
    final keeperId = _keeperId!;
    final keeper = group.items.firstWhere((m) => m.id == keeperId);
    final suggestion = ref.read(suggestKeepBestProvider).suggestWithReason(group.items);
    final isAutoSelected = keeper.id == suggestion.keeper.id;
    final columns = gridCrossAxisCountForWidth(
      MediaQuery.sizeOf(context).width,
    );
    final theme = Theme.of(context);

    return OneUiSubpageScaffold(
      title: l10n.duplicateReviewTitle,
      subtitle: l10n.duplicateReviewSubtitleImproved,
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
              : Text(l10n.duplicateReviewDeleteCount(selectedIds.length)),
        ),
      ],
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.duplicateKeeperExplanation,
                        style: theme.textTheme.bodySmall,
                      ),
                      if (isAutoSelected) ...[
                        const SizedBox(height: 4),
                        Text(
                          _keeperReasonText(context, suggestion.reason),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.75,
              ),
              itemCount: group.items.length,
              itemBuilder: (context, index) {
                final media = group.items[index];
                final isKeeper = media.id == keeperId;
                final isMarkedDelete = selectedIds.contains(media.id);
                final date = DateTime.fromMillisecondsSinceEpoch(media.sortDate);
                final dateStr = DateFormat.yMMMd(
                  Localizations.localeOf(context).toString(),
                ).format(date);

                return GestureDetector(
                  onTap: () {
                    if (isKeeper) {
                      _showKeeperInfo(context, media);
                    } else {
                      setState(() {
                        if (isMarkedDelete) {
                          selectedIds.remove(media.id);
                        } else {
                          selectedIds.add(media.id);
                        }
                      });
                    }
                  },
                  onLongPress: () {
                    _selectAsKeeper(media, group);
                  },
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: isKeeper ? 4 : 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isKeeper
                          ? BorderSide(
                              color: theme.colorScheme.primary,
                              width: 3,
                            )
                          : BorderSide.none,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              MediaThumbnail(
                                assetId: media.uri,
                                showVideoBadge: media.isVideo,
                              ),
                              if (isKeeper)
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          l10n.duplicateBestLabel,
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (isMarkedDelete && !isKeeper)
                                Container(
                                  color: Colors.red.withValues(alpha: 0.5),
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          color: isKeeper
                              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                              : null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dateStr,
                                style: theme.textTheme.labelSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatFileSize(media.size),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (media.width != null && media.height != null)
                                Text(
                                  '${media.width}×${media.height}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.duplicateTapToToggle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.duplicateLongPressToKeep,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showKeeperInfo(BuildContext context, MediaItem media) {
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.duplicateKeeperInfoSnack),
        duration: const Duration(seconds: 2),
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
