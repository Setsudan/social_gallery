import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_gallery/core/analysis/media_analysis_service.dart';
import 'package:social_gallery/core/auth/biometric_service.dart';
import 'package:social_gallery/core/auth/folder_unlock_store.dart';
import 'package:social_gallery/core/cache/cache_service.dart';
import 'package:social_gallery/core/cache/thumbnail_warmup_service.dart';
import 'package:social_gallery/core/permissions/media_permission_service.dart';
import 'package:social_gallery/core/permissions/storage_access_service.dart';
import 'package:social_gallery/data/datasources/photo_manager_datasource.dart';
import 'package:social_gallery/data/local/app_database.dart';
import 'package:social_gallery/data/repositories/folder_repository.dart';
import 'package:social_gallery/data/repositories/media_analysis_repository.dart';
import 'package:social_gallery/data/repositories/media_repository.dart';
import 'package:social_gallery/data/repositories/media_sync_repository.dart';
import 'package:social_gallery/core/sync/media_sync_service.dart';
import 'package:social_gallery/data/repositories/organize_repository.dart';
import 'package:social_gallery/data/repositories/preferences_repository.dart';
import 'package:social_gallery/data/repositories/travel_mode_repository.dart';
import 'package:social_gallery/domain/models/folder_info.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/domain/models/travel_mode.dart' as domain;
import 'package:social_gallery/domain/usecases/build_organize_queue.dart';
import 'package:social_gallery/domain/usecases/compute_shooting_stats.dart';
import 'package:social_gallery/domain/usecases/find_duplicate_groups.dart';
import 'package:social_gallery/domain/usecases/find_similar_groups.dart';
import 'package:social_gallery/domain/usecases/score_low_quality.dart';
import 'package:social_gallery/domain/usecases/suggest_keep_best.dart';
import 'package:social_gallery/domain/usecases/travel_mode_use_case.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
});

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  Future.microtask(() => database.repairFolderCovers());
  return database;
});

final mediaPermissionServiceProvider = Provider(
  (ref) => MediaPermissionService(),
);

final storageAccessServiceProvider = Provider((ref) => StorageAccessService());

final biometricServiceProvider = Provider((ref) => BiometricService());

final folderUnlockStoreProvider = ChangeNotifierProvider<FolderUnlockStore>((
  ref,
) {
  final store = FolderUnlockStore();
  ref.onDispose(store.dispose);
  return store;
});

final preferencesRepositoryProvider = Provider((ref) {
  return PreferencesRepository(ref.watch(sharedPreferencesProvider));
});

final photoManagerDatasourceProvider = Provider(
  (ref) => PhotoManagerDatasource(ref.watch(preferencesRepositoryProvider)),
);

final mediaSyncRepositoryProvider = Provider((ref) {
  return MediaSyncRepository(ref.watch(databaseProvider));
});

final mediaSyncServiceProvider = Provider((ref) {
  return MediaSyncService(
    ref.watch(mediaSyncRepositoryProvider),
    ref.watch(photoManagerDatasourceProvider),
    ref.watch(preferencesRepositoryProvider),
  );
});

final mediaRepositoryProvider = Provider((ref) {
  return MediaRepository(
    ref.watch(databaseProvider),
    ref.watch(photoManagerDatasourceProvider),
    ref.watch(preferencesRepositoryProvider),
    syncService: ref.watch(mediaSyncServiceProvider),
  );
});

final folderRepositoryProvider = Provider((ref) {
  return FolderRepository(ref.watch(databaseProvider));
});

final travelModeRepositoryProvider = Provider((ref) {
  return TravelModeRepository(ref.watch(databaseProvider));
});

final travelModeUseCaseProvider = Provider((ref) {
  return TravelModeUseCase(ref.watch(travelModeRepositoryProvider));
});

final cacheServiceProvider = Provider((ref) => CacheService());

final thumbnailWarmupServiceProvider = Provider(
  (ref) => ThumbnailWarmupService(),
);

final findDuplicateGroupsProvider = Provider((ref) => FindDuplicateGroups());

final suggestKeepBestProvider = Provider((ref) => SuggestKeepBest());

final organizeRepositoryProvider = Provider((ref) {
  return OrganizeRepository(ref.watch(sharedPreferencesProvider));
});

/// Reactive organize batch size for settings UI (backed by [OrganizeRepository]).
final organizeBatchSizeProvider = StateProvider<int>((ref) {
  return ref.read(organizeRepositoryProvider).batchSize;
});

final mediaAnalysisRepositoryProvider = Provider((ref) {
  return MediaAnalysisRepository(ref.watch(databaseProvider));
});

final mediaAnalysisServiceProvider = Provider((ref) => MediaAnalysisService());

final buildOrganizeQueueProvider = Provider((ref) => BuildOrganizeQueue());

final findSimilarGroupsProvider = Provider((ref) => FindSimilarGroups());

final scoreLowQualityProvider = Provider((ref) => ScoreLowQuality());

final computeShootingStatsProvider = Provider((ref) => ComputeShootingStats());

/// Reactive stream of all folders ordered by name.
final allFoldersProvider = StreamProvider<List<FolderInfo>>((ref) {
  return ref.watch(folderRepositoryProvider).watchAll();
});

/// Bounded first page of album media for cover pickers and light previews.
final folderCoverCandidatesProvider =
    FutureProvider.family<List<MediaItem>, String>((ref, path) {
      return ref.watch(mediaRepositoryProvider).getFolderMediaPage(path, 0);
    });

/// All travel modes ordered by start date.
final travelModesProvider = StreamProvider<List<domain.TravelMode>>((ref) {
  return ref.watch(travelModeRepositoryProvider).watchAll();
});

/// Soft-deleted media awaiting restore or permanent deletion.
final trashedMediaProvider = StreamProvider<List<MediaItem>>((ref) {
  return ref.watch(mediaRepositoryProvider).watchTrashedMedia();
});

/// Queued in-app location from a widget / deep link, consumed after startup.
final pendingDeepLinkLocationProvider = StateProvider<String?>((ref) => null);
