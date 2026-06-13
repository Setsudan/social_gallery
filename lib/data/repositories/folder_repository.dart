import 'package:social_gallery/data/local/app_database.dart';
import 'package:social_gallery/data/mappers/entity_mappers.dart';
import 'package:social_gallery/domain/models/folder_info.dart';
import 'package:social_gallery/domain/models/follow_status.dart';

class FolderRepository {
  FolderRepository(this._db);

  final AppDatabase _db;

  Stream<List<FolderInfo>> watchByFollowStatus(FollowStatus status) {
    return _db
        .watchFoldersByFollowStatus(status.storageValue)
        .map((rows) => rows.map(folderFromRow).toList());
  }

  Stream<List<FolderInfo>> watchAll() {
    return _db.watchAllFoldersOrdered().map(
      (rows) => rows.map(folderFromRow).toList(),
    );
  }

  Future<FolderInfo?> getFolder(String path) async {
    final row = await _db.getFolder(path);
    return row == null ? null : folderFromRow(row);
  }

  Stream<FolderInfo?> watchFolder(String path) {
    return _db
        .watchFolder(path)
        .map((row) => row == null ? null : folderFromRow(row));
  }

  Future<void> updateFollowStatus(
    String path,
    FollowStatus status, {
    bool? isBiometricLocked,
    String? biography,
  }) async {
    var effectiveStatus = status;
    final locking = isBiometricLocked == true;

    if (locking && status == FollowStatus.homeFeed) {
      effectiveStatus = FollowStatus.accountOnly;
    }

    await _db.updateFolderFollowStatus(
      path,
      effectiveStatus.storageValue,
      isBiometricLocked: isBiometricLocked,
      biography: biography,
    );

    if (locking) {
      await _db.updateFolderStories(path, false);
    }
  }

  Future<void> updateFolderStories(String path, bool showInStories) {
    return _db.updateFolderStories(path, showInStories);
  }

  Future<void> bulkUpdateFollowStatus(List<String> paths, FollowStatus status) {
    return _db.bulkUpdateFollowStatus(
      paths,
      status.storageValue,
      clearBiometric: status != FollowStatus.accountOnly,
    );
  }

  Future<List<FolderInfo>> searchFolders(String query) async {
    final rows = await _db.searchFolders(query);
    return rows.map(folderFromRow).toList();
  }

  Future<void> setCustomCover(String path, String? coverUri) {
    return _db.setFolderCustomCover(path, coverUri);
  }
}
