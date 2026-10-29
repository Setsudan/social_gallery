import 'package:flutter_test/flutter_test.dart';
import 'package:social_gallery/core/sync/gallery_sync_progress.dart';
import 'package:social_gallery/core/sync/media_sync_service.dart';
import 'package:social_gallery/data/datasources/photo_manager_datasource.dart';
import 'package:social_gallery/data/local/app_database.dart';
import 'package:social_gallery/data/repositories/media_repository.dart';
import 'package:social_gallery/data/repositories/preferences_repository.dart';

class _Database extends Fake implements AppDatabase {}

class _PhotoManagerDatasource extends Fake implements PhotoManagerDatasource {}

class _PreferencesRepository extends Fake implements PreferencesRepository {}

class _SyncService extends Fake implements MediaSyncService {
  bool? fastScan;
  bool Function()? shouldCancel;
  GallerySyncProgressCallback? onProgress;

  @override
  Future<void> syncFromDevice({
    bool fastScan = false,
    bool Function()? shouldCancel,
    GallerySyncProgressCallback? onProgress,
  }) async {
    this.fastScan = fastScan;
    this.shouldCancel = shouldCancel;
    this.onProgress = onProgress;
  }
}

void main() {
  test(
    'compatibility sync entry point forwards options to injected service',
    () async {
      final syncService = _SyncService();
      final mediaRepository = MediaRepository(
        _Database(),
        _PhotoManagerDatasource(),
        _PreferencesRepository(),
        syncService: syncService,
      );
      bool shouldCancel() => true;
      final progress = <GallerySyncProgress>[];
      await mediaRepository.syncFromDevice(
        fastScan: true,
        shouldCancel: shouldCancel,
        onProgress: progress.add,
      );
      expect(syncService.fastScan, isTrue);
      expect(syncService.shouldCancel, same(shouldCancel));
      syncService.onProgress?.call(
        const GallerySyncProgress(phase: 'saving', detail: 'Saving'),
      );
      expect(progress.single.phase, 'saving');
    },
  );
}
