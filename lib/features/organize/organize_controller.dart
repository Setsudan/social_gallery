import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/domain/models/organize_models.dart';
import 'package:social_gallery/domain/usecases/build_organize_queue.dart';

final organizeControllerProvider =
    StateNotifierProvider<OrganizeController, OrganizeState>((ref) {
  return OrganizeController(ref);
});

class OrganizeController extends StateNotifier<OrganizeState> {
  OrganizeController(this._ref) : super(const OrganizeState()) {
    _init();
  }

  final Ref _ref;
  final _buildQueue = BuildOrganizeQueue();
  final _undoStack = <OrganizeUndoAction>[];

  List<MediaItem> _pool = [];

  Future<void> _init() async {
    await loadBatch();
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

    final organizeRepo = _ref.read(organizeRepositoryProvider);
    final mediaRepo = _ref.read(mediaRepositoryProvider);

    switch (direction) {
      case OrganizeSwipeDirection.left:
        await organizeRepo.addPendingTrash(current.id);
        await organizeRepo.addProcessed(current.id);
        _undoStack.add(
          OrganizeUndoAction(type: OrganizeUndoType.trash, mediaId: current.id),
        );
        await organizeRepo.updateStats(
          organizeRepo.stats.copyWith(
            processedCount: organizeRepo.stats.processedCount + 1,
          ),
        );
      case OrganizeSwipeDirection.right:
        final wasFavorite = current.isFavorite;
        await mediaRepo.setFavorite(current.id, true);
        await organizeRepo.addProcessed(current.id);
        _undoStack.add(
          OrganizeUndoAction(
            type: OrganizeUndoType.like,
            mediaId: current.id,
            wasFavorite: wasFavorite,
          ),
        );
        await organizeRepo.updateStats(
          organizeRepo.stats.copyWith(
            processedCount: organizeRepo.stats.processedCount + 1,
            likedCount: organizeRepo.stats.likedCount + 1,
          ),
        );
      case OrganizeSwipeDirection.up:
        await organizeRepo.addProcessed(current.id);
        _undoStack.add(
          OrganizeUndoAction(type: OrganizeUndoType.keep, mediaId: current.id),
        );
        await organizeRepo.updateStats(
          organizeRepo.stats.copyWith(
            processedCount: organizeRepo.stats.processedCount + 1,
          ),
        );
      case OrganizeSwipeDirection.down:
        state = state.copyWith(showFolderDrop: true);
        return;
    }

    _advanceCard();
  }

  Future<void> moveToFolder(String targetFolderPath) async {
    final current = state.currentCard;
    if (current == null) return;

    final mediaRepo = _ref.read(mediaRepositoryProvider);
    final organizeRepo = _ref.read(organizeRepositoryProvider);

    await mediaRepo.moveMedia([current], targetFolderPath);
    await organizeRepo.addProcessed(current.id);
    _undoStack.add(
      OrganizeUndoAction(
        type: OrganizeUndoType.move,
        mediaId: current.id,
        sourceFolderPath: current.folderPath,
        targetFolderPath: targetFolderPath,
      ),
    );
    final newStats = organizeRepo.stats.copyWith(
      processedCount: organizeRepo.stats.processedCount + 1,
    );
    await organizeRepo.updateStats(newStats);
    state = state.copyWith(showFolderDrop: false);
    _advanceCard();
  }

  void dismissFolderDrop() {
    state = state.copyWith(showFolderDrop: false);
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
