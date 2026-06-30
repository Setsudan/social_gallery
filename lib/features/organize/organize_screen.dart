import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/animation/app_motion.dart';
import 'package:social_gallery/core/auth/folder_access.dart';
import 'package:social_gallery/core/utils/haptics.dart';
import 'package:social_gallery/domain/models/folder_info.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/domain/models/organize_models.dart';
import 'package:social_gallery/features/organize/organize_card_stack.dart';
import 'package:social_gallery/features/organize/organize_controller.dart';
import 'package:social_gallery/features/organize/organize_empty_state.dart';
import 'package:social_gallery/features/organize/organize_filter_sheet.dart';
import 'package:social_gallery/features/organize/organize_folder_strip.dart';
import 'package:social_gallery/features/organize/organize_stats_sheet.dart';
import 'package:social_gallery/features/organize/organize_trash_review_sheet.dart';

class OrganizeScreen extends ConsumerWidget {
  const OrganizeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(organizeControllerProvider);
    final controller = ref.read(organizeControllerProvider.notifier);
    final allFolders = ref.watch(allFoldersProvider).valueOrNull ?? [];
    final recentPaths =
        ref.read(organizeRepositoryProvider).recentFolderPaths;
    final sortedFolders = sortFoldersByRecent(allFolders, recentPaths);

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
          : _OrganizeActiveBody(
              cards: state.queue,
              folders: sortedFolders,
              onSwipe: (dir) {
                AppHaptics.light();
                controller.applySwipe(dir);
              },
              onFolderDrop: (path) =>
                  _handleFolderDrop(context, ref, controller, path),
              onShare: () => _shareCurrent(context, state),
              onFilter: () => _openFilter(context, ref, controller),
              onUndo: controller.undo,
            ),
      ),
    );
  }

  Future<void> _handleFolderDrop(
    BuildContext context,
    WidgetRef ref,
    OrganizeController controller,
    String folderPath,
  ) async {
    final folders = ref.read(allFoldersProvider).valueOrNull ?? [];
    FolderInfo? folder;
    for (final candidate in folders) {
      if (candidate.path == folderPath) {
        folder = candidate;
        break;
      }
    }
    if (folder != null) {
      final ok = await ensureFolderUnlocked(ref: ref, folder: folder);
      if (!ok) return;
    }
    await controller.moveToFolder(folderPath);
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

class _OrganizeActiveBody extends ConsumerStatefulWidget {
  const _OrganizeActiveBody({
    required this.cards,
    required this.folders,
    required this.onSwipe,
    required this.onFolderDrop,
    required this.onShare,
    required this.onFilter,
    required this.onUndo,
  });

  final List<MediaItem> cards;
  final List<FolderInfo> folders;
  final OrganizeSwipeCallback onSwipe;
  final OrganizeFolderDropCallback onFolderDrop;
  final VoidCallback onShare;
  final VoidCallback onFilter;
  final VoidCallback onUndo;

  @override
  ConsumerState<_OrganizeActiveBody> createState() =>
      _OrganizeActiveBodyState();
}

class _OrganizeActiveBodyState extends ConsumerState<_OrganizeActiveBody> {
  bool _folderDragActive = false;

  @override
  Widget build(BuildContext context) {
    final motion = AppMotion.of(context, ref);
    final actionsVisible = !_folderDragActive;

    return Stack(
      children: [
        OrganizeCardStack(
          cards: widget.cards,
          folders: widget.folders,
          onSwipe: widget.onSwipe,
          onFolderDrop: widget.onFolderDrop,
          onFolderDragChanged: (active) {
            if (_folderDragActive != active) {
              setState(() => _folderDragActive = active);
            }
          },
        ),
        _OrganizeActionFab(
          motion: motion,
          visible: actionsVisible,
          left: 16,
          bottom: 24,
          heroTag: 'organize_share',
          icon: Icons.share_outlined,
          onPressed: widget.onShare,
        ),
        _OrganizeActionFab(
          motion: motion,
          visible: actionsVisible,
          right: 16,
          bottom: 24,
          heroTag: 'organize_filter',
          icon: Icons.filter_list,
          onPressed: widget.onFilter,
        ),
        _OrganizeActionFab(
          motion: motion,
          visible: actionsVisible,
          left: 0,
          right: 0,
          bottom: 24,
          heroTag: 'organize_undo',
          icon: Icons.undo,
          onPressed: widget.onUndo,
          centered: true,
        ),
      ],
    );
  }
}

class _OrganizeActionFab extends StatelessWidget {
  const _OrganizeActionFab({
    required this.motion,
    required this.visible,
    required this.heroTag,
    required this.icon,
    required this.onPressed,
    this.left,
    this.right,
    this.bottom,
    this.centered = false,
  });

  final AppMotion motion;
  final bool visible;
  final String heroTag;
  final IconData icon;
  final VoidCallback onPressed;
  final double? left;
  final double? right;
  final double? bottom;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final fab = FloatingActionButton.small(
      heroTag: heroTag,
      onPressed: visible ? onPressed : null,
      child: Icon(icon),
    );

    return Positioned(
      left: left,
      right: right,
      bottom: bottom,
      child: AnimatedSlide(
        duration: motion.fade,
        curve: visible ? motion.enterCurve : motion.exitCurve,
        offset: visible ? Offset.zero : const Offset(0, 2),
        child: AnimatedOpacity(
          duration: motion.fadeFast,
          opacity: visible ? 1 : 0,
          child: IgnorePointer(
            ignoring: !visible,
            child: centered ? Center(child: fab) : fab,
          ),
        ),
      ),
    );
  }
}
