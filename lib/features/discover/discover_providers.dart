import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/features/discover/discover_hub_controller.dart';
import 'package:social_gallery/features/discover/duplicate_scan_controller.dart';
import 'package:social_gallery/domain/models/media_analysis_result.dart';
import 'package:social_gallery/domain/models/media_item.dart';

export 'package:social_gallery/features/discover/duplicate_scan_controller.dart'
    show duplicateScanControllerProvider,
        duplicateScanNotificationServiceProvider,
        DuplicateScanState;

/// Home-feed media plus cached analysis rows for deep-organize features.
class AnalysisLibrarySnapshot {
  const AnalysisLibrarySnapshot({
    required this.items,
    required this.analysisById,
  });

  final List<MediaItem> items;
  final Map<int, MediaAnalysisResult> analysisById;
}

typedef LowQualityEntry = ({MediaItem item, List<String> reasons});

/// Invalidates analysis-dependent providers after a new scan or sync.
void _invalidateAnalysisTargets(void Function(ProviderOrFamily provider) invalidate) {
  invalidate(analysisLibrarySnapshotProvider);
  invalidate(duplicateScanControllerProvider);
  invalidate(similarPhotoGroupsProvider);
  invalidate(lowQualityQueueProvider);
  invalidate(discoverHubProvider);
}

/// Call from widgets after analysis data changes.
void invalidateAnalysisProviders(WidgetRef ref) {
  _invalidateAnalysisTargets(ref.invalidate);
}

/// Call from providers/notifiers after analysis data changes.
void invalidateAnalysisProvidersFromRef(Ref ref) {
  _invalidateAnalysisTargets(ref.invalidate);
}

/// Home-feed media plus all cached analysis rows (basis for deep-organize providers).
final analysisLibrarySnapshotProvider =
    FutureProvider<AnalysisLibrarySnapshot>((ref) async {
  final mediaRepo = ref.watch(mediaRepositoryProvider);
  final analysisRepo = ref.watch(mediaAnalysisRepositoryProvider);
  final items = await mediaRepo.getAllHomeFeedMedia();
  final analysis = await analysisRepo.getAllCached();
  return AnalysisLibrarySnapshot(items: items, analysisById: analysis);
});

/// Burst-like photo groups from cached dHash analysis.
final similarPhotoGroupsProvider =
    FutureProvider<List<List<MediaItem>>>((ref) async {
  final snapshot = await ref.watch(analysisLibrarySnapshotProvider.future);
  if (snapshot.analysisById.isEmpty) return [];

  final groups = ref.read(findSimilarGroupsProvider)(
    items: snapshot.items,
    analysisById: snapshot.analysisById,
  );
  final byId = {for (final i in snapshot.items) i.id: i};

  return groups
      .map(
        (g) => g.mediaIds
            .map((id) => byId[id])
            .whereType<MediaItem>()
            .toList(),
      )
      .where((g) => g.length > 1)
      .toList();
});

/// Images flagged as low quality by [ScoreLowQuality].
final lowQualityQueueProvider = FutureProvider<List<LowQualityEntry>>((ref) async {
  final snapshot = await ref.watch(analysisLibrarySnapshotProvider.future);
  if (snapshot.analysisById.isEmpty) return [];

  final scored = ref.read(scoreLowQualityProvider)(
    items: snapshot.items,
    analysisById: snapshot.analysisById,
  );
  final byId = {for (final i in snapshot.items) i.id: i};

  return scored
      .where((s) => byId.containsKey(s.mediaId))
      .map((s) => (item: byId[s.mediaId]!, reasons: s.reasons))
      .toList();
});

/// Monthly shooting stats for the deep-organize stats screen.
final shootingStatsProvider =
    FutureProvider.family<ShootingStats, DateTime>((ref, month) async {
  final snapshot = await ref.watch(analysisLibrarySnapshotProvider.future);
  return ref.read(computeShootingStatsProvider)(
    items: snapshot.items,
    month: month,
  );
});

/// Discover hub badge counts (organize backlog, analysis results).
final discoverHubProvider =
    AsyncNotifierProvider<DiscoverHubController, DiscoverHubData>(
  DiscoverHubController.new,
);

/// Large JPEG candidates (3 MB+) for the compression tool.
final compressionCandidatesProvider = FutureProvider<List<MediaItem>>((ref) async {
  const thresholdBytes = 3 * 1024 * 1024;
  final snapshot = await ref.watch(analysisLibrarySnapshotProvider.future);
  return snapshot.items
      .where((i) => !i.isVideo && i.size >= thresholdBytes)
      .toList()
    ..sort((a, b) => b.size.compareTo(a.size));
});
