import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_gallery/app/providers/data_providers.dart';
import 'package:social_gallery/core/analysis/media_analysis_controller.dart';
import 'package:social_gallery/core/analysis/media_analysis_service.dart';
import 'package:social_gallery/data/repositories/media_analysis_repository.dart';
import 'package:social_gallery/data/repositories/media_repository.dart';
import 'package:social_gallery/domain/models/media_analysis_result.dart';
import 'package:social_gallery/domain/models/media_item.dart';

class _MediaRepository extends Fake implements MediaRepository {
  int loads = 0;
  Object? error;

  @override
  Future<List<MediaItem>> getAllHomeFeedMedia() async {
    loads++;
    if (error != null) throw error!;
    return [];
  }
}

class _AnalysisRepository extends Fake implements MediaAnalysisRepository {
  @override
  Future<Map<int, MediaAnalysisResult>> getAllCached() async => {};
}

class _AnalysisService extends Fake implements MediaAnalysisService {
  final progress = StreamController<MediaAnalysisProgress>();
  MediaAnalysisMode? requestedMode;

  @override
  Stream<MediaAnalysisProgress> scanLibrary({
    required List<MediaItem> items,
    Map<int, MediaAnalysisResult>? cachedById,
    MediaAnalysisNeedsScan? needsScan,
    void Function(MediaAnalysisResult result)? onResult,
    MediaAnalysisMode mode = MediaAnalysisMode.analyzeFull,
  }) {
    requestedMode = mode;
    return progress.stream;
  }
}

void main() {
  test('scan progress is zero for an empty library', () {
    expect(const MediaAnalysisScanState().progress, 0);
    expect(const MediaAnalysisScanState(scanned: 2, total: 4).progress, 0.5);
  });

  test(
    'reports progress, ignores duplicate starts, and completes an empty scan',
    () async {
      final mediaRepository = _MediaRepository();
      final analysisService = _AnalysisService();
      final container = ProviderContainer(
        overrides: [
          mediaRepositoryProvider.overrideWithValue(mediaRepository),
          mediaAnalysisRepositoryProvider.overrideWithValue(
            _AnalysisRepository(),
          ),
          mediaAnalysisServiceProvider.overrideWithValue(analysisService),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        mediaAnalysisControllerProvider.notifier,
      );
      final scanning = controller.startScan();
      expect(
        container.read(mediaAnalysisControllerProvider).isScanning,
        isTrue,
      );
      await controller.startScan();
      expect(mediaRepository.loads, 1);
      await Future<void>.delayed(Duration.zero);
      analysisService.progress.add(
        const MediaAnalysisProgress(scanned: 1, total: 2),
      );
      await Future<void>.delayed(Duration.zero);
      expect(container.read(mediaAnalysisControllerProvider).progress, 0.5);
      await analysisService.progress.close();
      await scanning;
      expect(analysisService.requestedMode, MediaAnalysisMode.analyzeFull);
      final state = container.read(mediaAnalysisControllerProvider);
      expect(state.isScanning, isFalse);
      expect(state.total, 0);
      expect(state.error, isNull);
    },
  );

  test('reports repository errors without leaving the scan running', () async {
    final mediaRepository = _MediaRepository()
      ..error = StateError('cannot read library');
    final container = ProviderContainer(
      overrides: [
        mediaRepositoryProvider.overrideWithValue(mediaRepository),
        mediaAnalysisRepositoryProvider.overrideWithValue(
          _AnalysisRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(mediaAnalysisControllerProvider.notifier).startScan();
    final state = container.read(mediaAnalysisControllerProvider);
    expect(state.isScanning, isFalse);
    expect(state.error, contains('cannot read library'));
  });
}
