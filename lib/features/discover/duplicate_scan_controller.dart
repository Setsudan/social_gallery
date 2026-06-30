import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/notifications/duplicate_scan_notification_service.dart';
import 'package:social_gallery/core/sync/gallery_sync_controller.dart';
import 'package:social_gallery/domain/models/duplicate_group.dart';
import 'package:social_gallery/domain/models/media_analysis_result.dart';

/// Progress and results of the background duplicate-photo scan.
class DuplicateScanState {
  const DuplicateScanState({
    this.isScanning = false,
    this.scanned = 0,
    this.total = 0,
    this.groups,
    this.error,
  });

  final bool isScanning;
  final int scanned;
  final int total;
  final List<DuplicateGroup>? groups;
  final String? error;

  double get progress => total == 0 ? 0 : scanned / total;

  bool get isComplete => groups != null && !isScanning;
}

/// Scans home-feed images for duplicates and notifies when complete.
class DuplicateScanController extends StateNotifier<DuplicateScanState> {
  DuplicateScanController(this._ref) : super(const DuplicateScanState());

  final Ref _ref;

  void ensureStarted() {
    if (state.isScanning || state.isComplete) return;
    unawaited(startScan());
  }

  Future<void> _waitForGallerySync() async {
    while (_ref.read(gallerySyncProvider).isRunning) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  Future<void> startScan() async {
    if (state.isScanning) return;

    final notifications = _ref.read(duplicateScanNotificationServiceProvider);

    state = DuplicateScanState(
      isScanning: true,
      scanned: 0,
      total: state.total,
      groups: state.groups,
    );

    await notifications.onScanStarted();

    try {
      await _waitForGallerySync();

      final mediaRepo = _ref.read(mediaRepositoryProvider);
      final analysisRepo = _ref.read(mediaAnalysisRepositoryProvider);
      final service = _ref.read(mediaAnalysisServiceProvider);
      final findGroups = _ref.read(findDuplicateGroupsProvider);

      final candidates = await mediaRepo.getPotentialDuplicates();
      if (candidates.length < 2) {
        state = const DuplicateScanState(groups: []);
        await notifications.onScanComplete(0);
        return;
      }

      final total = candidates.where((c) => !c.isVideo).length;
      state = DuplicateScanState(isScanning: true, scanned: 0, total: total);

      final cached = await analysisRepo.getAllCached();
      final hashesById = await service.ensureDHashesForItems(
        items: candidates,
        cachedHashes: {
          for (final entry in cached.entries) entry.key: entry.value.dHash,
        },
        onProgress: (scanned, progressTotal) {
          state = DuplicateScanState(
            isScanning: true,
            scanned: scanned,
            total: progressTotal,
          );
          unawaited(notifications.onScanProgress(scanned, progressTotal));
        },
      );

      for (final item in candidates) {
        final hash = hashesById[item.id];
        if (hash == null) continue;

        final existing = cached[item.id];
        if (existing?.dHash == hash) continue;

        await analysisRepo.saveResult(
          MediaAnalysisResult(
            mediaId: item.id,
            dHash: hash,
            blurScore: existing?.blurScore,
            exposureScore: existing?.exposureScore,
            isSolidColor: existing?.isSolidColor ?? false,
            faceCount: existing?.faceCount ?? 0,
            hasClosedEyes: existing?.hasClosedEyes ?? false,
            labels: existing?.labels ?? const [],
            scannedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      }

      final groups = findGroups(
        candidates: candidates,
        hashesById: hashesById,
      );

      state = DuplicateScanState(
        isScanning: false,
        scanned: total,
        total: total,
        groups: groups,
      );
      await notifications.onScanComplete(groups.length);
    } catch (e) {
      state = DuplicateScanState(
        isScanning: false,
        scanned: state.scanned,
        total: state.total,
        error: e.toString(),
      );
      await notifications.onScanFailed(e.toString());
    }
  }
}

final duplicateScanNotificationServiceProvider =
    Provider<DuplicateScanNotificationService>(
  (ref) => DuplicateScanNotificationService(),
);

final duplicateScanControllerProvider =
    StateNotifierProvider<DuplicateScanController, DuplicateScanState>(
  (ref) => DuplicateScanController(ref),
);
