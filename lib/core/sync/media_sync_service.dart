import 'package:social_gallery/core/sync/gallery_sync_progress.dart';
import 'package:social_gallery/data/datasources/media_scan_source.dart';
import 'package:social_gallery/data/mappers/media_sync_merge.dart';
import 'package:social_gallery/data/repositories/media_sync_repository.dart';
import 'package:social_gallery/data/repositories/preferences_repository.dart';

class MediaSyncService {
  MediaSyncService(
    this._mediaSyncRepository,
    this._scanSource,
    this._preferencesRepository,
  );

  final MediaSyncRepository _mediaSyncRepository;
  final MediaScanSource _scanSource;
  final PreferencesRepository _preferencesRepository;

  Future<void> syncFromDevice({
    bool fastScan = false,
    bool Function()? shouldCancel,
    GallerySyncProgressCallback? onProgress,
  }) async {
    final followStatusByFolderPath = await _mediaSyncRepository
        .getFolderFollowStatuses();
    final existingStateByMediaId = await _mediaSyncRepository.getMergeState();
    final trashedMediaIds = <int>{
      for (final entry in existingStateByMediaId.entries)
        if (entry.value.isTrashed) entry.key,
    };

    onProgress?.call(
      const GallerySyncProgress(
        phase: 'folders',
        detail: 'Reading albums on your device',
      ),
    );

    final folderRows = await _scanSource.loadFolders(
      followStatusByFolderPath,
      _preferencesRepository.hasCompletedInitialSetup,
    );
    if (shouldCancel?.call() == true) return;
    await _mediaSyncRepository.upsertFolders(folderRows);

    final scannedMediaIds = <int>{};
    var savedMediaCount = 0;

    await _scanSource.scanAllMedia(
      fastScan: fastScan,
      shouldCancel: shouldCancel,
      onProgress: onProgress,
      onChunk: (chunk) async {
        if (shouldCancel?.call() == true) return;
        final mergedRows = chunk.map((row) {
          final mediaId = row.id.value;
          scannedMediaIds.add(mediaId);
          return mergeScannedMedia(row, existingStateByMediaId[mediaId]);
        }).toList();

        await _mediaSyncRepository.upsertMediaChunk(mergedRows);
        savedMediaCount += mergedRows.length;
        onProgress?.call(
          GallerySyncProgress(
            phase: 'saving',
            detail: 'Saving $savedMediaCount items to your library',
            processed: savedMediaCount,
            total: savedMediaCount,
          ),
        );
      },
    );
    if (shouldCancel?.call() == true) return;

    // Only a completed scan can prune missing media; partial scans retain it.
    await _mediaSyncRepository.deleteMediaNotIn({
      ...scannedMediaIds,
      ...trashedMediaIds,
    });
    await _mediaSyncRepository.updateFolderCounts();
    await _mediaSyncRepository.repairFolderCovers();

    onProgress?.call(
      const GallerySyncProgress(phase: 'finishing', detail: 'Finishing setup'),
    );
  }
}
