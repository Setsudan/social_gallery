import 'package:social_gallery/core/sync/gallery_sync_progress.dart';
import 'package:social_gallery/data/local/app_database.dart';

abstract interface class MediaScanSource {
  Future<List<FoldersCompanion>> loadFolders(
    Map<String, String> existingFollowStatus,
    bool initialSetupComplete,
  );

  Future<void> scanAllMedia({
    bool fastScan = false,
    bool Function()? shouldCancel,
    GallerySyncProgressCallback? onProgress,
    required Future<void> Function(List<MediaItemsCompanion> chunk) onChunk,
  });
}
