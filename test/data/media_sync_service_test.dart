import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_gallery/core/sync/gallery_sync_progress.dart';
import 'package:social_gallery/core/sync/media_sync_service.dart';
import 'package:social_gallery/data/datasources/media_scan_source.dart';
import 'package:social_gallery/data/local/app_database.dart';
import 'package:social_gallery/data/repositories/media_sync_repository.dart';
import 'package:social_gallery/data/repositories/preferences_repository.dart';

class _ScanSource implements MediaScanSource {
  List<List<MediaItemsCompanion>> chunks = [];
  VoidCallback? afterFolders;
  VoidCallback? afterChunk;
  bool? receivedFastScan;
  Map<String, String>? receivedFollowStatuses;
  bool? receivedSetupComplete;

  @override
  Future<List<FoldersCompanion>> loadFolders(
    Map<String, String> existingFollowStatus,
    bool initialSetupComplete,
  ) async {
    receivedFollowStatuses = existingFollowStatus;
    receivedSetupComplete = initialSetupComplete;
    afterFolders?.call();
    return [FoldersCompanion.insert(path: '/album', name: 'Album')];
  }

  @override
  Future<void> scanAllMedia({
    bool fastScan = false,
    bool Function()? shouldCancel,
    GallerySyncProgressCallback? onProgress,
    required Future<void> Function(List<MediaItemsCompanion> chunk) onChunk,
  }) async {
    receivedFastScan = fastScan;
    for (final chunk in chunks) {
      await onChunk(chunk);
      afterChunk?.call();
    }
  }
}

typedef VoidCallback = void Function();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase database;
  late PreferencesRepository preferencesRepository;
  late _ScanSource scanSource;
  late MediaSyncService syncService;

  MediaItemsCompanion mediaRow(int mediaId, {bool isTrashed = false}) =>
      MediaItemsCompanion.insert(
        id: Value(mediaId),
        uri: 'asset-$mediaId',
        displayName: '$mediaId.jpg',
        folderName: 'Album',
        folderPath: '/album',
        dateAdded: mediaId,
        dateModified: mediaId,
        size: 100,
        mimeType: 'image/jpeg',
        isTrashed: Value(isTrashed),
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferencesRepository = PreferencesRepository(
      await SharedPreferences.getInstance(),
    );
    database = AppDatabase.forTesting(NativeDatabase.memory());
    scanSource = _ScanSource();
    syncService = MediaSyncService(
      MediaSyncRepository(database),
      scanSource,
      preferencesRepository,
    );
  });

  tearDown(() => database.close());

  test(
    'merges scanned chunks, removes missing media, and preserves trash',
    () async {
      await database.upsertFolders([
        FoldersCompanion.insert(
          path: '/album',
          name: 'Album',
          followStatus: const Value('HOME_FEED'),
        ),
      ]);
      await database.upsertMediaItemsChunk([
        mediaRow(1).copyWith(isFavorite: const Value(true)),
        mediaRow(2),
        mediaRow(3, isTrashed: true),
      ]);
      scanSource.chunks = [
        [mediaRow(1)],
        [mediaRow(4)],
      ];
      final progress = <GallerySyncProgress>[];

      await syncService.syncFromDevice(
        fastScan: true,
        onProgress: progress.add,
      );

      final media = await database.select(database.mediaItems).get();
      expect(media.map((row) => row.id).toSet(), {1, 3, 4});
      expect(media.singleWhere((row) => row.id == 1).isFavorite, isTrue);
      expect(media.singleWhere((row) => row.id == 3).isTrashed, isTrue);
      final folder = await database.getFolder('/album');
      expect(folder?.mediaCount, 2);
      expect(folder?.coverImageUri, 'asset-4');
      expect(scanSource.receivedFastScan, isTrue);
      expect(scanSource.receivedFollowStatuses, {'/album': 'HOME_FEED'});
      expect(
        scanSource.receivedSetupComplete,
        preferencesRepository.hasCompletedInitialSetup,
      );
      expect(progress.map((update) => update.phase), [
        'folders',
        'saving',
        'saving',
        'finishing',
      ]);
      expect(
        progress
            .where((update) => update.phase == 'saving')
            .map((update) => update.processed),
        [1, 2],
      );
    },
  );

  test(
    'cancellation after folder loading does not persist folders or scan',
    () async {
      var cancelled = false;
      scanSource.afterFolders = () => cancelled = true;
      await syncService.syncFromDevice(shouldCancel: () => cancelled);
      expect(await database.select(database.folders).get(), isEmpty);
      expect(scanSource.receivedFastScan, isNull);
    },
  );

  test(
    'cancellation after a chunk keeps partial data without deleting missing media',
    () async {
      await database.upsertMediaItemsChunk([mediaRow(99)]);
      var cancelled = false;
      scanSource.chunks = [
        [mediaRow(1)],
        [mediaRow(2)],
      ];
      scanSource.afterChunk = () => cancelled = true;
      final progress = <GallerySyncProgress>[];
      await syncService.syncFromDevice(
        shouldCancel: () => cancelled,
        onProgress: progress.add,
      );
      final media = await database.select(database.mediaItems).get();
      expect(media.map((row) => row.id).toSet(), {1, 99});
      expect(progress.map((update) => update.phase), ['folders', 'saving']);
    },
  );

  test(
    'empty successful scan deletes stale media but retains trashed media',
    () async {
      await database.upsertMediaItemsChunk([
        mediaRow(1),
        mediaRow(2, isTrashed: true),
      ]);
      await syncService.syncFromDevice();
      final media = await database.select(database.mediaItems).get();
      expect(media.map((row) => row.id), [2]);
    },
  );
}
