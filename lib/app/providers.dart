import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_gallery/core/auth/biometric_service.dart';
import 'package:social_gallery/core/auth/folder_unlock_store.dart';
import 'package:social_gallery/core/permissions/media_permission_service.dart';
import 'package:social_gallery/core/permissions/storage_access_service.dart';
import 'package:social_gallery/data/datasources/photo_manager_datasource.dart';
import 'package:social_gallery/data/local/app_database.dart';
import 'package:social_gallery/data/repositories/folder_repository.dart';
import 'package:social_gallery/data/repositories/media_repository.dart';
import 'package:social_gallery/data/repositories/preferences_repository.dart';
import 'package:social_gallery/domain/models/folder_info.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/domain/usecases/find_duplicate_groups.dart';
import 'package:social_gallery/domain/usecases/suggest_keep_best.dart';

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

final storageAccessServiceProvider = Provider(
  (ref) => StorageAccessService(),
);

final biometricServiceProvider = Provider((ref) => BiometricService());

final folderUnlockStoreProvider =
    ChangeNotifierProvider<FolderUnlockStore>((ref) {
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

final findDuplicateGroupsProvider = Provider((ref) => FindDuplicateGroups());

final suggestKeepBestProvider = Provider((ref) => SuggestKeepBest());

final syncStateProvider = StateProvider<bool>((ref) => false);

final activeProfileFolderProvider = StateProvider<String?>((ref) => null);

final allFoldersProvider = StreamProvider<List<FolderInfo>>((ref) {
  return ref.watch(folderRepositoryProvider).watchAll();
});

final folderMediaProvider = StreamProvider.family<List<MediaItem>, String>(
  (ref, path) {
    return ref.watch(mediaRepositoryProvider).watchFolderMedia(path);
  },
);
