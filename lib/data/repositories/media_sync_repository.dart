import 'package:social_gallery/data/local/app_database.dart';

class MediaSyncRepository {
  MediaSyncRepository(this._database);

  final AppDatabase _database;

  Future<Map<String, String>> getFolderFollowStatuses() async {
    final folders = await _database.select(_database.folders).get();
    return {for (final folder in folders) folder.path: folder.followStatus};
  }

  Future<Map<int, MediaSyncMergeState>> getMergeState() =>
      _database.getMediaSyncMergeState();

  Future<void> upsertFolders(List<FoldersCompanion> folders) =>
      _database.upsertFolders(folders);

  Future<void> upsertMediaChunk(List<MediaItemsCompanion> media) =>
      _database.upsertMediaItemsChunk(media);

  Future<void> deleteMediaNotIn(Set<int> retainedMediaIds) =>
      _database.deleteMediaNotIn(retainedMediaIds);

  Future<void> updateFolderCounts() => _database.updateFolderCounts();

  Future<void> repairFolderCovers() => _database.repairFolderCovers();
}
