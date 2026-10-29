import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers/data_providers.dart';
import 'package:social_gallery/core/analysis/media_analysis_service.dart';
import 'package:social_gallery/data/repositories/media_analysis_repository.dart';
import 'package:social_gallery/features/discover/discover_providers.dart';

/// Progress while [MediaAnalysisController] scans home-feed images.
class MediaAnalysisScanState {
  const MediaAnalysisScanState({
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

/// Runs on-device deep organize scan and writes results to [MediaAnalysisRepository].
class MediaAnalysisController extends StateNotifier<MediaAnalysisScanState> {
  MediaAnalysisController(this._ref) : super(const MediaAnalysisScanState());

  final Ref _ref;

  Future<void> startScan() async {
    if (state.isScanning) return;
    state = const MediaAnalysisScanState(isScanning: true);

    try {
      final mediaRepository = _ref.read(mediaRepositoryProvider);
      final analysisRepository = _ref.read(mediaAnalysisRepositoryProvider);
      final analysisService = _ref.read(mediaAnalysisServiceProvider);

      final items = await mediaRepository.getAllHomeFeedMedia();
      final cachedAnalysis = await analysisRepository.getAllCached();

      await for (final progress in analysisService.scanLibrary(
        items: items,
        cachedById: cachedAnalysis,
        needsScan: MediaAnalysisService.needsTaggingScan,
        mode: MediaAnalysisMode.analyzeFull,
        onResult: (result) async {
          await analysisRepository.saveResult(result);
        },
      )) {
        state = MediaAnalysisScanState(
          isScanning: true,
          scanned: progress.scanned,
          total: progress.total,
        );
      }

      state = MediaAnalysisScanState(
        isScanning: false,
        scanned: items.where((item) => !item.isVideo).length,
        total: items.where((item) => !item.isVideo).length,
      );
      invalidateAnalysisProvidersFromRef(_ref);
    } catch (error) {
      state = MediaAnalysisScanState(
        isScanning: false,
        error: error.toString(),
      );
    }
  }
}

final mediaAnalysisControllerProvider =
    StateNotifierProvider<MediaAnalysisController, MediaAnalysisScanState>(
      (ref) => MediaAnalysisController(ref),
    );
