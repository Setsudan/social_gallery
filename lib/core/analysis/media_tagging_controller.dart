import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/analysis/media_analysis_service.dart';

class MediaTaggingScanState {
  const MediaTaggingScanState({
    this.isScanning = false,
    this.scanned = 0,
    this.total = 0,
    this.error,
  });

  final bool isScanning;
  final int scanned;
  final int total;
  final String? error;

  double get progress => total == 0 ? 0 : scanned / total;
}

/// Incrementally tags searchable library photos for object and color search.
class MediaTaggingController extends StateNotifier<MediaTaggingScanState> {
  MediaTaggingController(this._ref) : super(const MediaTaggingScanState());

  final Ref _ref;
  bool _runQueued = false;

  Future<void> scheduleAfterLibrarySync() async {
    if (state.isScanning) {
      _runQueued = true;
      return;
    }
    unawaited(startScan());
  }

  Future<void> startScan() async {
    if (state.isScanning) return;
    state = const MediaTaggingScanState(isScanning: true);

    try {
      final mediaRepo = _ref.read(mediaRepositoryProvider);
      final analysisRepo = _ref.read(mediaAnalysisRepositoryProvider);
      final service = _ref.read(mediaAnalysisServiceProvider);

      final items = await mediaRepo.getAllSearchableMedia();
      final cached = await analysisRepo.getAllCached();
      final photos = items.where((item) => !item.isVideo).toList();
      final pending = photos
          .where(
            (item) => MediaAnalysisService.needsTaggingScan(
              item.id,
              cached[item.id],
            ),
          )
          .toList();

      state = MediaTaggingScanState(
        isScanning: true,
        total: pending.length,
      );

      var scanned = 0;
      for (final item in pending) {
        final result = await service.analyzeItem(item);
        if (result != null) {
          await analysisRepo.saveResult(result);
        }
        scanned++;
        state = MediaTaggingScanState(
          isScanning: true,
          scanned: scanned,
          total: pending.length,
        );
      }

      state = MediaTaggingScanState(
        isScanning: false,
        scanned: pending.length,
        total: pending.length,
      );
    } catch (e) {
      state = MediaTaggingScanState(isScanning: false, error: e.toString());
    } finally {
      if (_runQueued) {
        _runQueued = false;
        unawaited(startScan());
      }
    }
  }
}

final mediaTaggingControllerProvider =
    StateNotifierProvider<MediaTaggingController, MediaTaggingScanState>(
  (ref) => MediaTaggingController(ref),
);
