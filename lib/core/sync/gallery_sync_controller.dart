import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/workers/trash_cleanup_worker.dart';
import 'package:social_gallery/features/discover/discover_providers.dart'
    show invalidateAnalysisProvidersFromRef;
import 'package:social_gallery/shared/pagination/paginated_list_notifier.dart'
    show galleryPaginatedProvider, refreshFeedProvidersFromRef;

enum GallerySyncPhase {
  idle,
  cleaningTrash,
  loadingFolders,
  scanningMedia,
  savingMedia,
  finishing,
  done,
  error,
}

class GallerySyncState {
  const GallerySyncState({
    this.isRunning = false,
    this.dismissed = false,
    this.blocking = false,
    this.phase = GallerySyncPhase.idle,
    this.detail = '',
    this.processed = 0,
    this.total = 0,
    this.error,
  });

  final bool isRunning;
  final bool dismissed;

  /// When true, the full-screen sync overlay is shown (first launch only).
  final bool blocking;
  final GallerySyncPhase phase;
  final String detail;
  final int processed;
  final int total;
  final String? error;

  bool get showOverlay => isRunning && !dismissed && blocking;

  double? get progress => total > 0 ? processed / total : null;

  String get headline {
    return switch (phase) {
      GallerySyncPhase.cleaningTrash => 'Preparing your gallery',
      GallerySyncPhase.loadingFolders => 'Reading albums',
      GallerySyncPhase.scanningMedia => 'Scanning photos and videos',
      GallerySyncPhase.savingMedia => 'Saving library',
      GallerySyncPhase.finishing => 'Almost ready',
      GallerySyncPhase.done => 'Gallery ready',
      GallerySyncPhase.error => 'Sync interrupted',
      GallerySyncPhase.idle => 'Starting up',
    };
  }

  GallerySyncState copyWith({
    bool? isRunning,
    bool? dismissed,
    bool? blocking,
    GallerySyncPhase? phase,
    String? detail,
    int? processed,
    int? total,
    String? error,
    bool clearError = false,
  }) {
    return GallerySyncState(
      isRunning: isRunning ?? this.isRunning,
      dismissed: dismissed ?? this.dismissed,
      blocking: blocking ?? this.blocking,
      phase: phase ?? this.phase,
      detail: detail ?? this.detail,
      processed: processed ?? this.processed,
      total: total ?? this.total,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class GallerySyncController extends StateNotifier<GallerySyncState> {
  GallerySyncController(this._ref) : super(const GallerySyncState());

  final Ref _ref;
  bool _cancelRequested = false;

  Future<void> run({bool force = false}) async {
    if (state.isRunning && !force) return;

    _cancelRequested = false;
    final prefs = _ref.read(preferencesRepositoryProvider);
    final blocking = !prefs.hasCompletedInitialSetup;

    state = GallerySyncState(
      isRunning: true,
      blocking: blocking,
      phase: GallerySyncPhase.cleaningTrash,
      detail: blocking
          ? 'Removing expired trash items'
          : 'Checking for new media',
    );

    if (!blocking) {
      unawaited(_warmRecentThumbnails());
    }

    try {
      final repo = _ref.read(mediaRepositoryProvider);
      final settings = _ref.read(settingsProvider);

      await repo.cleanupExpiredTrash(settings.trashRetentionDays);
      if (_cancelRequested) {
        await _finishEarly(prefs);
        return;
      }

      await repo.syncFromDevice(
        fastScan: true,
        shouldCancel: () => _cancelRequested,
        onProgress: (progress) {
          if (_cancelRequested) return;
          final phase = switch (progress.phase) {
            'folders' => GallerySyncPhase.loadingFolders,
            'scanning' => GallerySyncPhase.scanningMedia,
            'saving' => GallerySyncPhase.savingMedia,
            'finishing' => GallerySyncPhase.finishing,
            _ => state.phase,
          };
          state = state.copyWith(
            phase: phase,
            detail: progress.detail,
            processed: progress.processed,
            total: progress.total,
            clearError: true,
          );
        },
      );

      if (_cancelRequested) {
        await _finishEarly(prefs);
        return;
      }

      try {
        await registerTrashCleanupWork();
      } catch (_) {}

      if (blocking) {
        unawaited(_warmRecentThumbnails());
      }
      _refreshFeeds(background: !blocking);
      state = state.copyWith(
        isRunning: false,
        blocking: false,
        phase: GallerySyncPhase.done,
        detail: 'Your library is up to date',
      );
    } catch (e, stack) {
      debugPrint('Gallery sync error: $e\n$stack');
      state = state.copyWith(
        isRunning: false,
        blocking: false,
        phase: GallerySyncPhase.error,
        detail: 'Something went wrong while syncing',
        error: e.toString(),
      );
    }
  }

  Future<void> _finishEarly(dynamic prefs) async {
    if (!prefs.hasCompletedInitialSetup) {
      await prefs.setInitialSetupComplete();
    }
    _refreshFeeds();
    state = state.copyWith(
      isRunning: false,
      blocking: false,
      phase: GallerySyncPhase.done,
      detail: 'Continuing with partial library',
    );
  }

  void dismissOverlay() {
    _cancelRequested = true;
    state = state.copyWith(dismissed: true, isRunning: false, blocking: false);
    _refreshFeeds();
    final prefs = _ref.read(preferencesRepositoryProvider);
    if (!prefs.hasCompletedInitialSetup) {
      unawaited(prefs.setInitialSetupComplete());
    }
  }

  Future<void> _warmRecentThumbnails() async {
    try {
      final items = await _ref.read(mediaRepositoryProvider).getGalleryMediaPage(0);
      final ids = items.map((item) => item.uri);
      await _ref.read(thumbnailWarmupServiceProvider).warmAssetIds(ids);
    } catch (_) {}
  }

  void _refreshFeeds({bool background = false}) {
    if (background) {
      refreshFeedProvidersFromRef(_ref);
      if (_ref.exists(galleryPaginatedProvider)) {
        unawaited(
          _ref.read(galleryPaginatedProvider.notifier).loadMore(refresh: true),
        );
      }
      return;
    }
    refreshFeedProvidersFromRef(_ref);
    _ref.invalidate(galleryPaginatedProvider);
    invalidateAnalysisProvidersFromRef(_ref);
  }
}

final gallerySyncProvider =
    StateNotifierProvider<GallerySyncController, GallerySyncState>(
  (ref) => GallerySyncController(ref),
);
