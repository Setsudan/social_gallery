import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/analysis/media_tagging_controller.dart'
    show mediaTaggingControllerProvider;
import 'package:social_gallery/core/workers/trash_cleanup_worker.dart';
import 'package:social_gallery/features/discover/discover_providers.dart'
    show invalidateAnalysisProvidersFromRef;
import 'package:social_gallery/features/discover/locations_providers.dart'
    show invalidateLocationProvidersFromRef;
import 'package:social_gallery/features/discover/location_index_controller.dart'
    show locationIndexControllerProvider;
import 'package:social_gallery/shared/pagination/paginated_list_notifier.dart'
    show refreshFeedProvidersFromRef;

/// Phase of an in-progress device-to-database gallery sync.
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

/// Observable sync progress for overlays and startup blocking UI.
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
      GallerySyncPhase.cleaningTrash => 'Preparing your library',
      GallerySyncPhase.loadingFolders => 'Reading albums',
      GallerySyncPhase.scanningMedia => 'Scanning photos and videos',
      GallerySyncPhase.savingMedia => 'Saving library index',
      GallerySyncPhase.finishing => 'Almost ready',
      GallerySyncPhase.done => 'Library index ready',
      GallerySyncPhase.error => 'Library sync interrupted',
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

/// Orchestrates device-to-DB sync with throttling and feed refresh on completion.
class GallerySyncController extends StateNotifier<GallerySyncState> {
  GallerySyncController(this._ref) : super(const GallerySyncState());

  static const _minSyncInterval = Duration(minutes: 5);
  static const _backgroundStartDelay = Duration(seconds: 2);

  final Ref _ref;
  bool _cancelRequested = false;

  Future<void> run({bool force = false}) async {
    if (state.isRunning && !force) return;

    if (!force) {
      final lastSync = _ref.read(preferencesRepositoryProvider).lastGallerySyncAt;
      if (lastSync != null &&
          DateTime.now().difference(lastSync) < _minSyncInterval) {
        return;
      }
    }

    _cancelRequested = false;

    final isFirstLibrarySync =
        _ref.read(preferencesRepositoryProvider).lastGallerySyncAt == null;

    state = GallerySyncState(
      isRunning: true,
      blocking: isFirstLibrarySync,
      phase: GallerySyncPhase.cleaningTrash,
      detail: 'Checking for new media',
    );

    await Future<void>.delayed(_backgroundStartDelay);
    if (_cancelRequested) {
      await _finishEarly();
      return;
    }

    try {
      final repo = _ref.read(mediaRepositoryProvider);
      final settings = _ref.read(settingsProvider);
      var earlyFeedRefreshDone = false;

      await repo.cleanupExpiredTrash(settings.trashRetentionDays);
      if (_cancelRequested) {
        await _finishEarly();
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

          // Sync indexes newest media first; refresh gallery as soon as the
          // first recent chunk lands so the UI is not blocked on a full scan.
          if (!earlyFeedRefreshDone &&
              progress.phase == 'saving' &&
              progress.processed > 0) {
            earlyFeedRefreshDone = true;
            _refreshFeeds(background: true);
          }
        },
      );

      if (_cancelRequested) {
        await _finishEarly();
        return;
      }

      try {
        await registerTrashCleanupWork();
      } catch (_) {}

      _refreshFeeds(background: true);
      invalidateAnalysisProvidersFromRef(_ref);
      invalidateLocationProvidersFromRef(_ref);
      _ref.read(locationIndexControllerProvider.notifier).scheduleAfterLibrarySync();
      _ref.read(mediaTaggingControllerProvider.notifier).scheduleAfterLibrarySync();
      unawaited(_ref.read(mediaRepositoryProvider).backfillScreenshotContentKinds());
      await _ref
          .read(preferencesRepositoryProvider)
          .setLastGallerySyncAt(DateTime.now());
      unawaited(_warmRecentThumbnails());
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

  Future<void> _finishEarly() async {
    _refreshFeeds();
    await _ref
        .read(preferencesRepositoryProvider)
        .setLastGallerySyncAt(DateTime.now());
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
  }

  Future<void> _warmRecentThumbnails() async {
    try {
      final items = await _ref.read(mediaRepositoryProvider).getGalleryMediaPage(0);
      final ids = items.map((item) => item.uri);
      await _ref.read(thumbnailWarmupServiceProvider).warmAssetIds(ids);
    } catch (_) {}
  }

  void _refreshFeeds({bool background = false}) {
    refreshFeedProvidersFromRef(_ref);
    if (!background) {
      invalidateAnalysisProvidersFromRef(_ref);
    }
  }
}

/// Riverpod provider for [GallerySyncController] sync state and actions.
final gallerySyncProvider =
    StateNotifierProvider<GallerySyncController, GallerySyncState>(
  (ref) => GallerySyncController(ref),
);
