import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/domain/models/media_analysis_result.dart';
import 'package:social_gallery/domain/models/organize_models.dart';

class DiscoverHubController extends AsyncNotifier<DiscoverHubData> {
  @override
  Future<DiscoverHubData> build() async {
    return _load();
  }

  Future<DiscoverHubData> _load() async {
    final mediaRepo = ref.read(mediaRepositoryProvider);
    final organizeRepo = ref.read(organizeRepositoryProvider);
    final analysisRepo = ref.read(mediaAnalysisRepositoryProvider);
    final findDuplicates = ref.read(findDuplicateGroupsProvider);
    final findSimilar = ref.read(findSimilarGroupsProvider);
    final scoreLowQuality = ref.read(scoreLowQualityProvider);
    final buildQueue = ref.read(buildOrganizeQueueProvider);

    final duplicates = await mediaRepo.getPotentialDuplicates();
    final groups = findDuplicates(duplicates);
    final dupItems = groups.fold<int>(0, (sum, g) => sum + g.count);

    final pool = await mediaRepo.getOrganizeMediaPool();
    final unprocessed = buildQueue.countRemaining(
      pool: pool,
      processedIds: organizeRepo.processedIds,
      pendingTrashIds: organizeRepo.pendingTrashIds,
      filter: const OrganizeFilter(),
    );

    final favorites = await mediaRepo.getFavoriteMediaList();
    final analysis = await analysisRepo.getAllCached();

    var similarCount = 0;
    var lowQualityCount = 0;
    if (analysis.isNotEmpty) {
      final allMedia = await mediaRepo.getAllHomeFeedMedia();
      similarCount = findSimilar(
        items: allMedia,
        analysisById: analysis,
      ).length;
      lowQualityCount = scoreLowQuality(
        items: allMedia,
        analysisById: analysis,
      ).length;
    }

    return DiscoverHubData(
      duplicateGroupCount: groups.length,
      duplicateItemCount: dupItems,
      similarGroupCount: similarCount,
      lowQualityCount: lowQualityCount,
      unprocessedCount: unprocessed,
      pendingTrashCount: organizeRepo.pendingTrashIds.length,
      likedCount: favorites.length,
      processedCount: organizeRepo.stats.processedCount,
      isLoading: false,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _load());
  }
}
