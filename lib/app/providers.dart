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
import 'package:social_gallery/domain/usecases/find_duplicate_groups.dart';
import 'package:social_gallery/domain/usecases/suggest_keep_best.dart';
import 'package:social_gallery/domain/usecases/travel_mode_use_case.dart';

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

final photoManagerDatasourceProvider = Provider(
  (ref) => PhotoManagerDatasource(),
);

final preferencesRepositoryProvider = Provider((ref) {
  return PreferencesRepository(ref.watch(sharedPreferencesProvider));
});

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

  const AppSettings({
    required this.themeMode,
    required this.fontSizeFactor,
    required this.animationSpeed,
    required this.trashRetentionDays,
    required this.cacheSizeLimitMb,
    required this.autoClearCacheOnClose,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    double? fontSizeFactor,
    double? animationSpeed,
    int? trashRetentionDays,
    int? cacheSizeLimitMb,
    bool? autoClearCacheOnClose,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      fontSizeFactor: fontSizeFactor ?? this.fontSizeFactor,
      animationSpeed: animationSpeed ?? this.animationSpeed,
      trashRetentionDays: trashRetentionDays ?? this.trashRetentionDays,
      cacheSizeLimitMb: cacheSizeLimitMb ?? this.cacheSizeLimitMb,
      autoClearCacheOnClose:
          autoClearCacheOnClose ?? this.autoClearCacheOnClose,
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
