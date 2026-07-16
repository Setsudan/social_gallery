import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/layout/responsive_grid.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/core/utils/haptics.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/shared/widgets/empty_state.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_tab_page_scaffold.dart';
import 'package:social_gallery/l10n/app_localizations.dart';

class TrashScreen extends ConsumerStatefulWidget {
  const TrashScreen({super.key});

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen> {
  final Set<int> _selectedIds = {};

  void _toggleSelect(MediaItem item) {
    setState(() {
      if (_selectedIds.contains(item.id)) {
        _selectedIds.remove(item.id);
      } else {
        _selectedIds.add(item.id);
      }
    });
  }

  void _startSelection(MediaItem item) {
    setState(() {
      _selectedIds.add(item.id);
    });
  }

  Future<void> _bulkRestore(List<MediaItem> allItems) async {
    final toRestore = allItems
        .where((i) => _selectedIds.contains(i.id))
        .toList();
    if (toRestore.isEmpty) return;

    AppHaptics.light();
    final repo = ref.read(mediaRepositoryProvider);
    await repo.restoreMedia(toRestore);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.snackbarRestoredItems(toRestore.length)),
        ),
      );
    }
    setState(() {
      _selectedIds.clear();
    });
    AppHaptics.success();
  }

  Future<void> _bulkDeletePermanently(List<MediaItem> allItems) async {
    final l10n = context.l10n;
    final toDelete = allItems
        .where((i) => _selectedIds.contains(i.id))
        .toList();
    if (toDelete.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.trashDeletePermanentlyTitle),
        content: Text(l10n.trashDeletePermanentlyMessage(toDelete.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(l10n.trashDeletePermanentlyAction),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      AppHaptics.light();
      final repo = ref.read(mediaRepositoryProvider);
      await repo.permanentlyDeleteMedia(toDelete);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.snackbarPermanentlyDeleted(toDelete.length),
            ),
          ),
        );
      }
      setState(() {
        _selectedIds.clear();
      });
      AppHaptics.heavy();
    }
  }

  String _getTrashedPath(String originalPath) {
    final dir = p.dirname(originalPath);
    final name = p.basename(originalPath);
    return p.join(dir, '.trashed_$name');
  }

  String _daysLabel(AppLocalizations l10n, int remainingDays) {
    if (remainingDays <= 0) {
      return l10n.trashExpiresToday;
    }
    return l10n.trashDaysLeft(remainingDays);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final trashedAsync = ref.watch(trashedMediaProvider);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final inSelectionMode = _selectedIds.isNotEmpty;

    return trashedAsync.when(
      data: (items) {
        return Scaffold(
          appBar: AppBar(
            title: inSelectionMode
                ? Text(l10n.selectionCount(_selectedIds.length))
                : null,
            leading: inSelectionMode
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _selectedIds.clear()),
                  )
                : IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      AppHaptics.light();
                      context.pop();
                    },
                  ),
            actions: inSelectionMode
                ? [
                    IconButton(
                      icon: const Icon(Icons.settings_backup_restore),
                      tooltip: l10n.tooltipRestoreSelected,
                      onPressed: () => _bulkRestore(items),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_forever_outlined),
                      tooltip: l10n.tooltipDeletePermanently,
                      onPressed: () => _bulkDeletePermanently(items),
                    ),
                  ]
                : null,
          ),
          body: items.isEmpty
              ? EmptyState(
                  title: l10n.trashEmptyTitle,
                  message: l10n.trashEmptyMessage,
                  icon: Icons.delete_outline,
                )
              : Builder(
                  builder: (context) {
                    final columns = gridCrossAxisCountForWidth(
                      MediaQuery.sizeOf(context).width,
                    );

                    return GridView.builder(
                      padding: const EdgeInsets.all(OneUiSpacing.sm),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isSelected = _selectedIds.contains(item.id);

                        final elapsedMs =
                            DateTime.now().millisecondsSinceEpoch -
                            (item.trashedAt ?? 0);
                        final elapsedDays =
                            (elapsedMs / (24 * 60 * 60 * 1000)).floor();
                        final remainingDays =
                            settings.trashRetentionDays - elapsedDays;
                        final daysLabel = _daysLabel(l10n, remainingDays);

                        final trashedPath = item.originalPath != null
                            ? _getTrashedPath(item.originalPath!)
                            : '';
                        final trashedFile = File(trashedPath);

                        return GestureDetector(
                          onLongPress: () {
                            AppHaptics.medium();
                            _startSelection(item);
                          },
                          onTap: () {
                            if (inSelectionMode) {
                              AppHaptics.medium();
                              _toggleSelect(item);
                            } else {
                              showDialog<void>(
                                context: context,
                                builder: (context) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  insetPadding: const EdgeInsets.all(16),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          16,
                                        ),
                                        child: trashedFile.existsSync()
                                            ? Image.file(
                                                trashedFile,
                                                fit: BoxFit.contain,
                                                cacheWidth:
                                                    (MediaQuery.sizeOf(context)
                                                                .shortestSide *
                                                            MediaQuery.devicePixelRatioOf(
                                                              context,
                                                            ))
                                                        .ceil()
                                                        .clamp(720, 4096),
                                              )
                                            : const Center(
                                                child: Icon(
                                                  Icons.image,
                                                  size: 64,
                                                  color: Colors.white24,
                                                ),
                                              ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: CircleAvatar(
                                          backgroundColor: Colors.black54,
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(context),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 16,
                                        left: 16,
                                        right: 16,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.8,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                item.displayName,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                daysLabel,
                                                style: TextStyle(
                                                  color: theme
                                                      .colorScheme
                                                      .errorContainer,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          },
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    color:
                                        theme.colorScheme.surfaceContainerHighest,
                                    child: trashedFile.existsSync()
                                        ? Image.file(
                                            trashedFile,
                                            fit: BoxFit.cover,
                                            cacheWidth: 500,
                                          )
                                        : const Center(
                                            child: Icon(
                                              Icons.broken_image_outlined,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 4,
                                left: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    daysLabel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: theme.colorScheme.primary,
                                      width: 3,
                                    ),
                                  ),
                                  child: Center(
                                    child: CircleAvatar(
                                      backgroundColor:
                                          theme.colorScheme.primary,
                                      radius: 16,
                                      child: Icon(
                                        Icons.check,
                                        color: theme.colorScheme.onPrimary,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => OneUiTabPageScaffold(
        error: e,
        body: const SizedBox.shrink(),
      ),
    );
  }
}
