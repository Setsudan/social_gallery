import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/domain/models/media_analysis_result.dart';
import 'package:social_gallery/domain/models/organize_models.dart';
import 'package:social_gallery/features/discover/discover_providers.dart';

/// Aggregates organize and analysis counts for the Discover hub screen.
class DiscoverHubController extends AsyncNotifier<DiscoverHubData> {
  @override
  Future<DiscoverHubData> build() async {
    return _load();
  }

  Future<DiscoverHubData> _load() async {
    final mediaRepo = ref.read(mediaRepositoryProvider);
    final organizeRepo = ref.read(organizeRepositoryProvider);
    final buildQueue = ref.read(buildOrganizeQueueProvider);

    final pool = await mediaRepo.getOrganizeMediaPool();
    final unprocessed = buildQueue.countRemaining(
      pool: pool,
      processedIds: organizeRepo.processedIds,
      pendingTrashIds: organizeRepo.pendingTrashIds,
      filter: const OrganizeFilter(),
    );

    final favorites = await mediaRepo.getFavoriteMediaList();
    final geotagged = await mediaRepo.getMediaWithLocation();

    var similarCount = 0;
    var lowQualityCount = 0;
    final snapshot = await ref.watch(analysisLibrarySnapshotProvider.future);
    if (snapshot.analysisById.isNotEmpty) {
      similarCount = (await ref.watch(similarPhotoGroupsProvider.future)).length;
      lowQualityCount =
          (await ref.watch(lowQualityQueueProvider.future)).length;
    }

    return DiscoverHubData(
      similarGroupCount: similarCount,
      lowQualityCount: lowQualityCount,
      unprocessedCount: unprocessed,
      pendingTrashCount: organizeRepo.pendingTrashIds.length,
      likedCount: favorites.length,
      processedCount: organizeRepo.stats.processedCount,
      geotaggedCount: geotagged.length,
      isLoading: false,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _load());
  }
}
