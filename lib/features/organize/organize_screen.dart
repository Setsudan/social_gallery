import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/utils/haptics.dart';
import 'package:social_gallery/domain/models/organize_models.dart';
import 'package:social_gallery/features/organize/organize_card_stack.dart';
import 'package:social_gallery/features/organize/organize_controller.dart';
import 'package:social_gallery/features/organize/organize_empty_state.dart';
import 'package:social_gallery/features/organize/organize_filter_sheet.dart';
import 'package:social_gallery/features/organize/organize_stats_sheet.dart';
import 'package:social_gallery/features/organize/organize_trash_review_sheet.dart';
import 'package:social_gallery/shared/widgets/folder_picker_sheet.dart';

class OrganizeScreen extends ConsumerWidget {
  const OrganizeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(organizeControllerProvider);
    final controller = ref.read(organizeControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(
          state.batchComplete
              ? 'Organize'
              : '${state.batchDone} / ${state.batchSize}',
        ),
        actions: [
          if (state.pendingTrashCount > 0)
            IconButton(
              icon: Badge(
                label: Text('${state.pendingTrashCount}'),
                child: const Icon(Icons.delete_outline),
              ),
              onPressed: () => _openTrashReview(context, ref, controller),
            ),
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            onPressed: () => OrganizeStatsSheet.show(context, state.stats),
          ),
        ],
      ),
      body: SafeArea(
        child: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.batchComplete
          ? OrganizeEmptyState(
              remainingCount: state.remainingPoolCount,
              pendingTrashCount: state.pendingTrashCount,
              onNextBatch: controller.loadBatch,
              onViewTrash: () => _openTrashReview(context, ref, controller),
              onChangeFilter: () => _openFilter(context, ref, controller),
              onReleaseKept: controller.releaseKept,
            )
          : Stack(
              children: [
                OrganizeCardStack(
                  cards: state.queue,
                  onSwipe: (dir) {
                    AppHaptics.light();
                    controller.applySwipe(dir);
                  },
                  onDragDown: () {
                    controller.applySwipe(OrganizeSwipeDirection.down);
                  },
                ),
                if (state.showFolderDrop) _FolderDropOverlay(controller: controller),
                Positioned(
                  left: 16,
                  bottom: 24,
                  child: FloatingActionButton.small(
                    heroTag: 'organize_share',
                    onPressed: () => _shareCurrent(context, state),
                    child: const Icon(Icons.share_outlined),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 24,
                  child: FloatingActionButton.small(
                    heroTag: 'organize_filter',
                    onPressed: () => _openFilter(context, ref, controller),
                    child: const Icon(Icons.filter_list),
                  ),
                ),
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: FloatingActionButton.small(
                      heroTag: 'organize_undo',
                      onPressed: controller.undo,
                      child: const Icon(Icons.undo),
                    ),
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Future<void> _shareCurrent(BuildContext context, OrganizeState state) async {
    final item = state.currentCard;
    if (item == null) return;
    await Share.share('Sharing ${item.displayName}');
  }

  void _openFilter(
    BuildContext context,
    WidgetRef ref,
    OrganizeController controller,
  ) {
    final state = ref.read(organizeControllerProvider);
    OrganizeFilterSheet.show(
      context,
      initial: state.filter,
      onApply: controller.setFilter,
    );
  }

  void _openTrashReview(
    BuildContext context,
    WidgetRef ref,
    OrganizeController controller,
  ) {
    final items = controller.pendingTrashItems;
    if (items.isEmpty) return;
    OrganizeTrashReviewSheet.show(
      context,
      items: items,
      onConfirm: controller.confirmTrash,
    );
  }
}

class _FolderDropOverlay extends ConsumerWidget {
  const _FolderDropOverlay({required this.controller});

  final OrganizeController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(allFoldersProvider).valueOrNull ?? [];

    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black54,
        child: Column(
          children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Move to folder',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: folders.length,
                      separatorBuilder: (_, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final folder = folders[index];
                        return ActionChip(
                          label: Text(folder.name),
                          onPressed: () async {
                            await controller.moveToFolder(folder.path);
                          },
                        );
                      },
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final path = await showFolderPickerSheet(
                        context: context,
                        ref: ref,
                        folders: folders,
                      );
                      if (path != null) {
                        await controller.moveToFolder(path);
                      }
                    },
                    child: const Text('Browse all folders'),
                  ),
                  TextButton(
                    onPressed: controller.dismissFolderDrop,
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
