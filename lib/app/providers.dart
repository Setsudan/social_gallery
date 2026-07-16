import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/core/l10n/app_locale_preference.dart';
import 'package:social_gallery/core/theme/accent_presets.dart';
import 'package:social_gallery/core/theme/app_theme_variant.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_gallery/core/auth/biometric_service.dart';
import 'package:social_gallery/core/auth/folder_unlock_store.dart';
import 'package:social_gallery/core/sync/gallery_sync_controller.dart';
import 'package:social_gallery/core/permissions/media_permission_service.dart';
import 'package:social_gallery/core/permissions/storage_access_service.dart';
import 'package:social_gallery/data/datasources/photo_manager_datasource.dart';
import 'package:social_gallery/data/local/app_database.dart';
import 'package:social_gallery/core/cache/cache_service.dart';
import 'package:social_gallery/core/cache/thumbnail_warmup_service.dart';
import 'package:social_gallery/data/repositories/folder_repository.dart';
import 'package:social_gallery/data/repositories/media_repository.dart';
import 'package:social_gallery/data/repositories/preferences_repository.dart';
import 'package:social_gallery/data/repositories/travel_mode_repository.dart';
import 'package:social_gallery/domain/models/folder_info.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/domain/models/desktop_gallery_grid_size.dart';
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
import 'package:social_gallery/features/discover/discover_providers.dart';
import 'package:social_gallery/shared/pagination/paginated_list_notifier.dart';
import 'package:social_gallery/core/backup/backup_deep_link.dart';
import 'package:social_gallery/core/backup/desktop_availability_service.dart';
import 'package:social_gallery/core/backup/desktop_backup_controller.dart';
import 'package:social_gallery/core/backup/desktop_discovery_service.dart';
import 'package:social_gallery/core/backup/desktop_library_controller.dart';
import 'package:social_gallery/core/backup/vault_password_store.dart';
import 'package:social_gallery/core/notifications/desktop_backup_notification_service.dart';
import 'package:social_gallery/core/backup/pairing_service.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';

/// Application-wide Riverpod providers: database, repositories, settings, and use cases.
export 'package:social_gallery/features/discover/discover_providers.dart'
    show discoverHubProvider;

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
});

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  Future.microtask(() => db.repairFolderCovers());
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

final mediaAnalysisServiceProvider = Provider((ref) {
  return MediaAnalysisService();
});

final buildOrganizeQueueProvider = Provider((ref) => BuildOrganizeQueue());

final findSimilarGroupsProvider = Provider((ref) => FindSimilarGroups());

final scoreLowQualityProvider = Provider((ref) => ScoreLowQuality());

final computeShootingStatsProvider = Provider((ref) => ComputeShootingStats());

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

      await for (final progress in service.scanLibrary(
        items: items,
        cachedById: cached,
        needsScan: MediaAnalysisService.needsTaggingScan,
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
      invalidateAnalysisProvidersFromRef(_ref);
    } catch (e) {
      state = MediaAnalysisScanState(isScanning: false, error: e.toString());
    }
  }
}

final mediaAnalysisControllerProvider =
    StateNotifierProvider<MediaAnalysisController, MediaAnalysisScanState>(
  (ref) => MediaAnalysisController(ref),
);

final syncStateProvider = Provider<bool>((ref) {
  return ref.watch(gallerySyncProvider.select((state) => state.isRunning));
});

final activeProfileFolderProvider = StateProvider<String?>((ref) => null);

/// Reactive stream of all folders ordered by name.
final allFoldersProvider = StreamProvider<List<FolderInfo>>((ref) {
  return ref.watch(folderRepositoryProvider).watchAll();
});

/// Reactive media list for one album; [path] is the folder path key.
final folderMediaProvider = StreamProvider.family<List<MediaItem>, String>((
  ref,
  path,
) {
  return ref.watch(mediaRepositoryProvider).watchFolderMedia(path);
});

/// Bounded first page of album media for cover pickers and light previews.
final folderCoverCandidatesProvider =
    FutureProvider.family<List<MediaItem>, String>((ref, path) {
  return ref.watch(mediaRepositoryProvider).getFolderMediaPage(path, 0);
});

/// User preferences mirrored from [PreferencesRepository] for UI binding.
class AppSettings {
  final AppThemeVariant appTheme;
  final Color accentColor;
  final double fontSizeFactor;
  final double animationSpeed;
  final int trashRetentionDays;
  final int cacheSizeLimitMb;
  final bool autoClearCacheOnClose;
  final bool galleryViewMode;
  final DesktopGalleryGridSize desktopGalleryGridSize;
  final AppLocalePreference localePreference;

  const AppSettings({
    required this.appTheme,
    required this.accentColor,
    required this.fontSizeFactor,
    required this.animationSpeed,
    required this.trashRetentionDays,
    required this.cacheSizeLimitMb,
    required this.autoClearCacheOnClose,
    required this.galleryViewMode,
    required this.desktopGalleryGridSize,
    required this.localePreference,
  });

  AppSettings copyWith({
    AppThemeVariant? appTheme,
    Color? accentColor,
    double? fontSizeFactor,
    double? animationSpeed,
    int? trashRetentionDays,
    int? cacheSizeLimitMb,
    bool? autoClearCacheOnClose,
    bool? galleryViewMode,
    DesktopGalleryGridSize? desktopGalleryGridSize,
    AppLocalePreference? localePreference,
  }) {
    return AppSettings(
      appTheme: appTheme ?? this.appTheme,
      accentColor: accentColor ?? this.accentColor,
      fontSizeFactor: fontSizeFactor ?? this.fontSizeFactor,
      animationSpeed: animationSpeed ?? this.animationSpeed,
      trashRetentionDays: trashRetentionDays ?? this.trashRetentionDays,
      cacheSizeLimitMb: cacheSizeLimitMb ?? this.cacheSizeLimitMb,
      autoClearCacheOnClose:
          autoClearCacheOnClose ?? this.autoClearCacheOnClose,
      galleryViewMode: galleryViewMode ?? this.galleryViewMode,
      desktopGalleryGridSize:
          desktopGalleryGridSize ?? this.desktopGalleryGridSize,
      localePreference: localePreference ?? this.localePreference,
    );
  }
}

/// Persists [AppSettings] changes to SharedPreferences.
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._prefs) : super(_loadInitial(_prefs));

  final PreferencesRepository _prefs;

  static AppSettings _loadInitial(PreferencesRepository prefs) {
    return AppSettings(
      appTheme: appThemeVariantFromString(prefs.themeMode),
      accentColor: AccentPresets.resolve(prefs.accentColorArgb),
      fontSizeFactor: prefs.fontSizeFactor,
      animationSpeed: prefs.animationSpeed,
      trashRetentionDays: prefs.trashRetentionDays,
      cacheSizeLimitMb: prefs.cacheSizeLimitMb,
      autoClearCacheOnClose: prefs.autoClearCacheOnClose,
      galleryViewMode: prefs.galleryViewMode,
      desktopGalleryGridSize: prefs.desktopGalleryGridSize,
      localePreference: prefs.localePreference,
    );
  }

  Future<void> setAppTheme(AppThemeVariant variant) async {
    state = state.copyWith(appTheme: variant);
    await _prefs.setThemeMode(appThemeVariantToString(variant));
  }

  Future<void> setAccentColor(Color color) async {
    if (!AccentPresets.isPreset(color)) return;
    state = state.copyWith(accentColor: color);
    await _prefs.setAccentColorArgb(color.toARGB32());
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

  Future<void> setDesktopGalleryGridSize(DesktopGalleryGridSize size) async {
    state = state.copyWith(desktopGalleryGridSize: size);
    await _prefs.setDesktopGalleryGridSize(size);
  }

  Future<void> setLocalePreference(AppLocalePreference preference) async {
    state = state.copyWith(localePreference: preference);
    await _prefs.setLocalePreference(preference);
  }
}

/// All travel modes ordered by start date.
final travelModesProvider = StreamProvider<List<domain.TravelMode>>((ref) {
  return ref.watch(travelModeRepositoryProvider).watchAll();
});

/// Global settings: theme, gallery view mode, trash retention, cache limits.
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((
  ref,
) {
  final prefs = ref.watch(preferencesRepositoryProvider);
  return SettingsNotifier(prefs);
});

/// Soft-deleted media awaiting restore or permanent deletion.
final trashedMediaProvider = StreamProvider<List<MediaItem>>((ref) {
  return ref.watch(mediaRepositoryProvider).watchTrashedMedia();
});

final pairingServiceProvider = Provider((ref) {
  return PairingService(ref.watch(preferencesRepositoryProvider));
});

final pendingBackupPairProvider =
    StateProvider<BackupPairingParams?>((ref) => null);

/// Queued in-app location from a widget / deep link, consumed after startup.
final pendingDeepLinkLocationProvider = StateProvider<String?>((ref) => null);

final desktopDiscoveryServiceProvider = Provider((ref) {
  return DesktopDiscoveryService();
});

final vaultPasswordStoreProvider = Provider((ref) {
  return VaultPasswordStore();
});

final desktopAvailabilityServiceProvider = Provider((ref) {
  return DesktopAvailabilityService(
    ref.watch(preferencesRepositoryProvider),
    ref.watch(desktopDiscoveryServiceProvider),
  );
});

final desktopBackupProvider =
    StateNotifierProvider<DesktopBackupController, DesktopBackupState>((ref) {
  final controller = DesktopBackupController(
    ref.watch(preferencesRepositoryProvider),
    ref.watch(mediaRepositoryProvider),
    ref.watch(desktopAvailabilityServiceProvider),
    ref.watch(pairingServiceProvider),
    ref.watch(desktopDiscoveryServiceProvider),
    ref.watch(vaultPasswordStoreProvider),
    notifications: usesFilesystemGallery
        ? null
        : ref.watch(desktopBackupNotificationServiceProvider),
    onLibraryRefresh: () async {
      if (usesFilesystemGallery) {
        await ref.read(gallerySyncProvider.notifier).run(force: true);
      }
    },
    onBackupFinished: () {
      if (!usesFilesystemGallery) {
        refreshFeedProvidersFromRef(ref);
      }
    },
    isGallerySyncRunning: () => ref.read(gallerySyncProvider).isRunning,
    waitForGallerySync: () async {
      while (ref.read(gallerySyncProvider).isRunning) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    },
  );
  controller.startHeartbeat();
  ref.onDispose(controller.dispose);
  return controller;
});

final desktopLibraryProvider =
    StateNotifierProvider<DesktopLibraryController, DesktopLibraryState>((ref) {
  final controller = DesktopLibraryController(
    ref.watch(preferencesRepositoryProvider),
    ref.watch(desktopAvailabilityServiceProvider),
    ref.watch(vaultPasswordStoreProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});
