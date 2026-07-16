import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/domain/models/organize_models.dart';
import 'package:social_gallery/domain/usecases/build_organize_queue.dart';
import 'package:social_gallery/shared/pagination/paginated_list_notifier.dart';

/// Riverpod state for the organize swipe session (queue, undo, trash review).
final organizeControllerProvider =
    StateNotifierProvider.autoDispose<OrganizeController, OrganizeState>((ref) {
  final controller = OrganizeController(ref);
  ref.onDispose(controller.disposeController);
  return controller;
});

/// Loads organize batches, handles swipes, undo, and trash review commits.
class OrganizeController extends StateNotifier<OrganizeState> {
  OrganizeController(this._ref) : super(const OrganizeState()) {
    _init();
  }

  final Ref _ref;
  final _buildQueue = BuildOrganizeQueue();
  final _undoStack = <OrganizeUndoAction>[];

  List<MediaItem> _pool = [];
  Future<void> _persistChain = Future<void>.value();
  Timer? _feedRefreshTimer;
  bool _feedsDirty = false;

  Future<void> _init() async {
    await loadBatch();
  }

  void disposeController() {
    flushFeedRefresh();
  }

  Future<void> loadBatch() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      _pool = await _ref.read(mediaRepositoryProvider).getOrganizeMediaPool();
      final organizeRepo = _ref.read(organizeRepositoryProvider);
      final queue = _buildQueue(
        pool: _pool,
        processedIds: organizeRepo.processedIds,
        pendingTrashIds: organizeRepo.pendingTrashIds,
        filter: organizeRepo.filter,
        order: organizeRepo.queueOrder,
        batchSize: organizeRepo.batchSize,
      );
      final remaining = _buildQueue.countRemaining(
        pool: _pool,
        processedIds: organizeRepo.processedIds,
        pendingTrashIds: organizeRepo.pendingTrashIds,
        filter: organizeRepo.filter,
      );

      state = OrganizeState(
        queue: queue,
        batchDone: 0,
        isLoading: false,
        pendingTrashCount: organizeRepo.pendingTrashIds.length,
        remainingPoolCount: remaining,
        stats: organizeRepo.stats,
        filter: organizeRepo.filter,
        batchSize: organizeRepo.batchSize,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> applySwipe(OrganizeSwipeDirection direction) async {
    final current = state.currentCard;
    if (current == null) return;
    if (direction == OrganizeSwipeDirection.down) return;

    final organizeRepo = _ref.read(organizeRepositoryProvider);
    final mediaRepo = _ref.read(mediaRepositoryProvider);
    final wasFavorite = current.isFavorite;

    switch (direction) {
      case OrganizeSwipeDirection.left:
        _undoStack.add(
          OrganizeUndoAction(type: OrganizeUndoType.trash, mediaId: current.id),
        );
      case OrganizeSwipeDirection.right:
        _undoStack.add(
          OrganizeUndoAction(
            type: OrganizeUndoType.like,
            mediaId: current.id,
            wasFavorite: wasFavorite,
          ),
        );
      case OrganizeSwipeDirection.up:
        _undoStack.add(
          OrganizeUndoAction(type: OrganizeUndoType.keep, mediaId: current.id),
        );
      case OrganizeSwipeDirection.down:
        return;
    }

    _advanceCard();

    _enqueuePersist(() async {
      switch (direction) {
        case OrganizeSwipeDirection.left:
          await organizeRepo.addPendingTrash(current.id);
          await organizeRepo.addProcessed(current.id);
          await organizeRepo.updateStats(
            organizeRepo.stats.copyWith(
              processedCount: organizeRepo.stats.processedCount + 1,
            ),
          );
          if (mounted) {
            state = state.copyWith(
              pendingTrashCount: organizeRepo.pendingTrashIds.length,
              stats: organizeRepo.stats,
            );
          }
        case OrganizeSwipeDirection.right:
          await mediaRepo.setFavorite(current.id, true);
          await organizeRepo.addProcessed(current.id);
          await organizeRepo.updateStats(
            organizeRepo.stats.copyWith(
              processedCount: organizeRepo.stats.processedCount + 1,
              likedCount: organizeRepo.stats.likedCount + 1,
            ),
          );
          if (mounted) {
            state = state.copyWith(stats: organizeRepo.stats);
          }
        case OrganizeSwipeDirection.up:
          await organizeRepo.addProcessed(current.id);
          await organizeRepo.updateStats(
            organizeRepo.stats.copyWith(
              processedCount: organizeRepo.stats.processedCount + 1,
            ),
          );
          if (mounted) {
            state = state.copyWith(stats: organizeRepo.stats);
          }
        case OrganizeSwipeDirection.down:
          break;
      }
    });
  }

  /// Advances the card immediately, then moves media in the background.
  /// Returns `false` if the move failed and the card was restored.
  Future<bool> moveToFolder(String targetFolderPath) async {
    final current = state.currentCard;
    if (current == null) return false;

    final undoAction = OrganizeUndoAction(
      type: OrganizeUndoType.move,
      mediaId: current.id,
      sourceFolderPath: current.folderPath,
      targetFolderPath: targetFolderPath,
    );
    _undoStack.add(undoAction);
    _advanceCard();

    final completer = Completer<bool>();
    _enqueuePersist(() async {
      final mediaRepo = _ref.read(mediaRepositoryProvider);
      final organizeRepo = _ref.read(organizeRepositoryProvider);
      try {
        final moved = await mediaRepo.moveMedia([current], targetFolderPath);
        if (moved == 0) {
          _rollbackFailedMove(current, undoAction);
          completer.complete(false);
          return;
        }

        await organizeRepo.recordRecentFolder(targetFolderPath);
        await organizeRepo.addProcessed(current.id);
        final newStats = organizeRepo.stats.copyWith(
          processedCount: organizeRepo.stats.processedCount + 1,
        );
        await organizeRepo.updateStats(newStats);
        if (mounted) {
          state = state.copyWith(stats: organizeRepo.stats);
        }
        _scheduleFeedRefresh();
        completer.complete(true);
      } catch (_) {
        _rollbackFailedMove(current, undoAction);
        completer.complete(false);
      }
    });

    return completer.future;
  }

  void _rollbackFailedMove(MediaItem item, OrganizeUndoAction undoAction) {
    _undoStack.removeWhere(
      (action) =>
          action.mediaId == undoAction.mediaId &&
          action.type == OrganizeUndoType.move &&
          action.targetFolderPath == undoAction.targetFolderPath,
    );

    if (!mounted) return;
    if (state.queue.any((m) => m.id == item.id)) return;

    state = state.copyWith(
      queue: [item, ...state.queue],
      batchDone: state.batchDone > 0 ? state.batchDone - 1 : 0,
    );
  }

  void _enqueuePersist(Future<void> Function() op) {
    _persistChain = _persistChain.then((_) => op()).catchError((_) {});
  }

  void _scheduleFeedRefresh() {
    _feedsDirty = true;
    _feedRefreshTimer?.cancel();
    // Short debounce so rapid drops coalesce, but gallery updates quickly.
    _feedRefreshTimer = Timer(const Duration(milliseconds: 250), () {
      _feedRefreshTimer = null;
      if (!_feedsDirty) return;
      _feedsDirty = false;
      refreshFeedProvidersFromRef(_ref);
    });
  }

  void flushFeedRefresh() {
    _feedRefreshTimer?.cancel();
    _feedRefreshTimer = null;
    if (!_feedsDirty) return;
    _feedsDirty = false;
    refreshFeedProvidersFromRef(_ref);
  }

  void _advanceCard() {
    final organizeRepo = _ref.read(organizeRepositoryProvider);
    final newQueue = List<MediaItem>.from(state.queue)..removeAt(0);
    state = state.copyWith(
      queue: newQueue,
      batchDone: state.batchDone + 1,
      pendingTrashCount: organizeRepo.pendingTrashIds.length,
      stats: organizeRepo.stats,
    );
  }

  Future<void> undo() async {
    await _persistChain;
    if (_undoStack.isEmpty) return;
    final action = _undoStack.removeLast();
    final organizeRepo = _ref.read(organizeRepositoryProvider);
    final mediaRepo = _ref.read(mediaRepositoryProvider);

    await organizeRepo.removeProcessed(action.mediaId);

    switch (action.type) {
      case OrganizeUndoType.trash:
        await organizeRepo.removePendingTrash(action.mediaId);
      case OrganizeUndoType.like:
        await mediaRepo.setFavorite(action.mediaId, action.wasFavorite);
      case OrganizeUndoType.keep:
        break;
      case OrganizeUndoType.move:
        final item = await mediaRepo.getMediaById(action.mediaId);
        if (item != null && action.sourceFolderPath != null) {
          await mediaRepo.moveMedia([item], action.sourceFolderPath!);
          _scheduleFeedRefresh();
        }
    }

    final item = await mediaRepo.getMediaById(action.mediaId);
    if (item != null) {
      final newQueue = [item, ...state.queue];
      state = state.copyWith(
        queue: newQueue,
        batchDone: state.batchDone > 0 ? state.batchDone - 1 : 0,
        pendingTrashCount: organizeRepo.pendingTrashIds.length,
        stats: organizeRepo.stats,
      );
    }
  }

  Future<void> confirmTrash(List<int> selectedIds) async {
    await _persistChain;
    final mediaRepo = _ref.read(mediaRepositoryProvider);
    final organizeRepo = _ref.read(organizeRepositoryProvider);

    final items = <MediaItem>[];
    for (final id in selectedIds) {
      final item = await mediaRepo.getMediaById(id);
      if (item != null) items.add(item);
    }

    if (items.isNotEmpty) {
      await mediaRepo.deleteFromDevice(items);
      var savedBytes = organizeRepo.stats.savedBytes;
      for (final item in items) {
        savedBytes += item.size;
      }
      final newStats = organizeRepo.stats.copyWith(
        deletedCount: organizeRepo.stats.deletedCount + items.length,
        savedBytes: savedBytes,
      );
      await organizeRepo.updateStats(newStats);
    }

    for (final id in selectedIds) {
      await organizeRepo.removePendingTrash(id);
    }

    state = state.copyWith(
      pendingTrashCount: organizeRepo.pendingTrashIds.length,
      stats: organizeRepo.stats,
    );
    refreshFeedProvidersFromRef(_ref);
  }

  Future<void> setFilter(OrganizeFilter filter) async {
    await _ref.read(organizeRepositoryProvider).setFilter(filter);
    await loadBatch();
  }

  Future<void> releaseKept() async {
    await _ref.read(organizeRepositoryProvider).clearProcessed();
    await loadBatch();
  }

  List<MediaItem> get pendingTrashItems {
    final organizeRepo = _ref.read(organizeRepositoryProvider);
    return _pool
        .where((i) => organizeRepo.pendingTrashIds.contains(i.id))
        .toList();
  }
}
