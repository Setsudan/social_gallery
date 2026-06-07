import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_gallery/core/auth/biometric_service.dart';
import 'package:social_gallery/core/auth/folder_unlock_store.dart';
import 'package:social_gallery/core/permissions/media_permission_service.dart';
import 'package:social_gallery/core/permissions/storage_access_service.dart';
import 'package:social_gallery/data/datasources/photo_manager_datasource.dart';
import 'package:social_gallery/data/local/app_database.dart';
import 'package:social_gallery/core/cache/cache_service.dart';
import 'package:social_gallery/data/repositories/folder_repository.dart';
import 'package:social_gallery/data/repositories/media_repository.dart';
import 'package:social_gallery/data/repositories/preferences_repository.dart';
import 'package:social_gallery/data/repositories/travel_mode_repository.dart';
import 'package:social_gallery/domain/models/folder_info.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/domain/models/travel_mode.dart' as domain;
import 'package:social_gallery/core/analysis/media_analysis_service.dart';
import 'package:social_gallery/data/repositories/media_analysis_repository.dart';
import 'package:social_gallery/data/repositories/organize_repository.dart';
import 'package:social_gallery/domain/models/media_analysis_result.dart';
import 'package:social_gallery/domain/usecases/build_organize_queue.dart';
import 'package:social_gallery/domain/usecases/compute_shooting_stats.dart';
import 'package:social_gallery/domain/usecases/find_duplicate_groups.dart';
import 'package:social_gallery/domain/usecases/find_similar_groups.dart';
import 'package:social_gallery/domain/usecases/score_low_quality.dart';
import 'package:social_gallery/domain/usecases/suggest_keep_best.dart';
import 'package:social_gallery/domain/usecases/travel_mode_use_case.dart';
import 'package:social_gallery/features/discover/discover_hub_controller.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
});

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
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

final mediaRepositoryProvider = Provider((ref) {
  return MediaRepository(
    ref.watch(databaseProvider),
    ref.watch(photoManagerDatasourceProvider),
    ref.watch(preferencesRepositoryProvider),
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

final findDuplicateGroupsProvider = Provider((ref) => FindDuplicateGroups());

final suggestKeepBestProvider = Provider((ref) => SuggestKeepBest());

final organizeRepositoryProvider = Provider((ref) {
  return OrganizeRepository(ref.watch(sharedPreferencesProvider));
});

final mediaAnalysisRepositoryProvider = Provider((ref) {
  return MediaAnalysisRepository(ref.watch(databaseProvider));
});

final mediaAnalysisServiceProvider = Provider((ref) {
  return MediaAnalysisService();
});

final buildOrganizeQueueProvider = Provider((ref) => BuildOrganizeQueue());

final findSimilarGroupsProvider = Provider((ref) => FindSimilarGroups());

final scoreLowQualityProvider = Provider((ref) => ScoreLowQuality());

final computeShootingStatsProvider = Provider((ref) => ComputeShootingStats());

final discoverHubProvider =
    AsyncNotifierProvider<DiscoverHubController, DiscoverHubData>(
  DiscoverHubController.new,
);

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

class MediaAnalysisController extends StateNotifier<MediaAnalysisScanState> {
  MediaAnalysisController(this._ref) : super(const MediaAnalysisScanState());

  final Ref _ref;

  Future<Map<int, MediaAnalysisResult>> getCachedAnalysis() async {
    return _ref.read(mediaAnalysisRepositoryProvider).getAllCached();
  }

  Future<void> startScan() async {
    if (state.isScanning) return;
    state = const MediaAnalysisScanState(isScanning: true);

    try {
      final mediaRepo = _ref.read(mediaRepositoryProvider);
      final analysisRepo = _ref.read(mediaAnalysisRepositoryProvider);
      final service = _ref.read(mediaAnalysisServiceProvider);

      final items = await mediaRepo.getAllHomeFeedMedia();
      final cached = await analysisRepo.getAllCached();
      final scannedIds = cached.keys.toSet();

      await for (final progress in service.scanLibrary(
        items: items,
        alreadyScanned: scannedIds,
        onResult: (result) async {
          await analysisRepo.saveResult(result);
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
        scanned: items.where((i) => !i.isVideo).length,
        total: items.where((i) => !i.isVideo).length,
      );
      _ref.invalidate(discoverHubProvider);
    } catch (e) {
      state = MediaAnalysisScanState(isScanning: false, error: e.toString());
    }
  }
}

final mediaAnalysisControllerProvider =
    StateNotifierProvider<MediaAnalysisController, MediaAnalysisScanState>(
  (ref) => MediaAnalysisController(ref),
);

final syncStateProvider = StateProvider<bool>((ref) => false);

final activeProfileFolderProvider = StateProvider<String?>((ref) => null);

final allFoldersProvider = StreamProvider<List<FolderInfo>>((ref) {
  return ref.watch(folderRepositoryProvider).watchAll();
});

final folderMediaProvider = StreamProvider.family<List<MediaItem>, String>((
  ref,
  path,
) {
  return ref.watch(mediaRepositoryProvider).watchFolderMedia(path);
});

class AppSettings {
  final ThemeMode themeMode;
  final double fontSizeFactor;
  final double animationSpeed;
  final int trashRetentionDays;
  final int cacheSizeLimitMb;
  final bool autoClearCacheOnClose;
  final bool galleryViewMode;

  const AppSettings({
    required this.themeMode,
    required this.fontSizeFactor,
    required this.animationSpeed,
    required this.trashRetentionDays,
    required this.cacheSizeLimitMb,
    required this.autoClearCacheOnClose,
    required this.galleryViewMode,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    double? fontSizeFactor,
    double? animationSpeed,
    int? trashRetentionDays,
    int? cacheSizeLimitMb,
    bool? autoClearCacheOnClose,
    bool? galleryViewMode,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      fontSizeFactor: fontSizeFactor ?? this.fontSizeFactor,
      animationSpeed: animationSpeed ?? this.animationSpeed,
      trashRetentionDays: trashRetentionDays ?? this.trashRetentionDays,
      cacheSizeLimitMb: cacheSizeLimitMb ?? this.cacheSizeLimitMb,
      autoClearCacheOnClose:
          autoClearCacheOnClose ?? this.autoClearCacheOnClose,
      galleryViewMode: galleryViewMode ?? this.galleryViewMode,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._prefs) : super(_loadInitial(_prefs));

  final PreferencesRepository _prefs;

  static AppSettings _loadInitial(PreferencesRepository prefs) {
    final modeStr = prefs.themeMode;
    ThemeMode mode = ThemeMode.system;
    if (modeStr == 'light') mode = ThemeMode.light;
    if (modeStr == 'dark') mode = ThemeMode.dark;

    return AppSettings(
      themeMode: mode,
      fontSizeFactor: prefs.fontSizeFactor,
      animationSpeed: prefs.animationSpeed,
      trashRetentionDays: prefs.trashRetentionDays,
      cacheSizeLimitMb: prefs.cacheSizeLimitMb,
      autoClearCacheOnClose: prefs.autoClearCacheOnClose,
      galleryViewMode: prefs.galleryViewMode,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    String modeStr = 'system';
    if (mode == ThemeMode.light) modeStr = 'light';
    if (mode == ThemeMode.dark) modeStr = 'dark';
    await _prefs.setThemeMode(modeStr);
  }

  Future<void> setFontSizeFactor(double factor) async {
    state = state.copyWith(fontSizeFactor: factor);
    await _prefs.setFontSizeFactor(factor);
  }

  Future<void> setAnimationSpeed(double speed) async {
    state = state.copyWith(animationSpeed: speed);
    await _prefs.setAnimationSpeed(speed);
  }

  Future<void> setTrashRetentionDays(int days) async {
    state = state.copyWith(trashRetentionDays: days);
    await _prefs.setTrashRetentionDays(days);
  }

  Future<void> setCacheSizeLimitMb(int mb) async {
    state = state.copyWith(cacheSizeLimitMb: mb);
    await _prefs.setCacheSizeLimitMb(mb);
  }

  Future<void> setAutoClearCacheOnClose(bool enabled) async {
    state = state.copyWith(autoClearCacheOnClose: enabled);
    await _prefs.setAutoClearCacheOnClose(enabled);
  }

  Future<void> setGalleryViewMode(bool enabled) async {
    state = state.copyWith(galleryViewMode: enabled);
    await _prefs.setGalleryViewMode(enabled);
  }
}

final travelModesProvider = StreamProvider<List<domain.TravelMode>>((ref) {
  return ref.watch(travelModeRepositoryProvider).watchAll();
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((
  ref,
) {
  final prefs = ref.watch(preferencesRepositoryProvider);
  return SettingsNotifier(prefs);
});

final trashedMediaProvider = StreamProvider<List<MediaItem>>((ref) {
  return ref.watch(mediaRepositoryProvider).watchTrashedMedia();
});
