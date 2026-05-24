import 'package:drift/drift.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:social_gallery/data/local/app_database.dart';

class PhotoManagerDatasource {
  Future<List<AssetPathEntity>> listAlbums() async {
    return PhotoManager.getAssetPathList(
      type: RequestType.common,
      hasAll: true,
    );
  }

  Future<List<MediaItemsCompanion>> loadAllMedia() async {
    final albums = await listAlbums();
    final companions = <MediaItemsCompanion>[];

    for (final album in albums) {
      if (album.isAll) continue;
      final count = await album.assetCountAsync;
      if (count == 0) continue;

      final assets = await album.getAssetListRange(start: 0, end: count);
      final folderPath = album.id;
      final folderName = album.name;

      for (final asset in assets) {
        final file = await asset.file;
        companions.add(
          MediaItemsCompanion.insert(
            id: Value(_stableId(asset)),
            uri: asset.id,
            displayName: asset.title ?? 'media_${asset.id}',
            folderName: folderName,
            folderPath: folderPath,
            dateAdded: asset.createDateTime.millisecondsSinceEpoch,
            dateModified: asset.modifiedDateTime.millisecondsSinceEpoch,
            dateTaken: Value(
              asset.createDateTime.millisecondsSinceEpoch,
            ),
            size: await _assetSize(asset, file?.lengthSync()),
            mimeType: _mimeType(asset),
            width: Value(asset.width),
            height: Value(asset.height),
            videoDuration: Value(
              asset.type == AssetType.video ? asset.duration : null,
            ),
          ),
        );
      }
    }

    return companions;
  }

  Future<List<FoldersCompanion>> loadFolders(
    Map<String, String> existingFollowStatus,
    bool initialSetupComplete,
  ) async {
    final albums = await listAlbums();
    final rows = <FoldersCompanion>[];

    for (final album in albums) {
      if (album.isAll) continue;
      final path = album.id;
      final count = await album.assetCountAsync;
      final cover = count > 0
          ? (await album.getAssetListRange(start: 0, end: 1)).firstOrNull
          : null;
      final coverPath = cover != null ? (await cover.file)?.path : null;
      final existing = existingFollowStatus[path];
      final followStatus = existing ??
          (initialSetupComplete ? 'UNFOLLOWED' : 'HOME_FEED');

      rows.add(
        FoldersCompanion.insert(
          path: path,
          name: album.name,
          mediaCount: Value(count),
          lastModified: Value(DateTime.now().millisecondsSinceEpoch),
          coverImageUri: Value(coverPath),
          followStatus: Value(followStatus),
        ),
      );
    }

    return rows;
  }

  Future<bool> deleteAssets(List<String> assetIds) async {
    final entities = <AssetEntity>[];
    for (final id in assetIds) {
      final entity = await AssetEntity.fromId(id);
      if (entity != null) {
        entities.add(entity);
      }
    }
    if (entities.isEmpty) return false;
    final result = await PhotoManager.editor.deleteWithIds(
      entities.map((e) => e.id).toList(),
    );
    return result.isNotEmpty;
  }

  int _stableId(AssetEntity asset) {
    final parsed = int.tryParse(asset.id);
    if (parsed != null) return parsed;
    return asset.id.hashCode & 0x7FFFFFFF;
  }

  Future<int> _assetSize(AssetEntity asset, int? fileSize) async {
    if (fileSize != null && fileSize > 0) return fileSize;
    final file = await asset.file;
    return file?.lengthSync() ?? 0;
  }

  String _mimeType(AssetEntity asset) {
    switch (asset.type) {
      case AssetType.video:
        return 'video/mp4';
      case AssetType.image:
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
