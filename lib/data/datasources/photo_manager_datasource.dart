import 'dart:io';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:photo_manager/photo_manager.dart';
import 'package:social_gallery/core/media/asset_media_loader.dart';
import 'package:social_gallery/core/media/asset_media_kind.dart';
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
        final kind = AssetMediaLoader.classify(asset);
        final mimeType = await AssetMediaLoader.inferMimeType(asset);
        companions.add(
          MediaItemsCompanion.insert(
            id: Value(_stableId(asset)),
            uri: asset.id,
            displayName: asset.title ?? 'media_${asset.id}',
            folderName: folderName,
            folderPath: folderPath,
            dateAdded: asset.createDateTime.millisecondsSinceEpoch,
            dateModified: asset.modifiedDateTime.millisecondsSinceEpoch,
            dateTaken: Value(asset.createDateTime.millisecondsSinceEpoch),
            size: await _assetSize(asset, file?.lengthSync()),
            mimeType: mimeType,
            width: Value(asset.width),
            height: Value(asset.height),
            videoDuration: Value(
              kind == AssetMediaKind.video ? asset.duration : null,
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
      final followStatus =
          existing ?? (initialSetupComplete ? 'UNFOLLOWED' : 'HOME_FEED');

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

  // --- NEW WORK: Disk File Operations ---

  Future<String?> createAlbumFolder(String folderName) async {
    if (!Platform.isAndroid) return null;
    try {
      final pictures = Directory('/storage/emulated/0/Pictures');
      if (!await pictures.exists()) return null;
      final newFolder = Directory(p.join(pictures.path, folderName));
      if (!await newFolder.exists()) {
        await newFolder.create(recursive: true);
      }
      await PhotoManager.clearFileCache();
      return newFolder.path;
    } catch (_) {
      return null;
    }
  }

  Future<bool> moveAssetOnDisk(String assetId, String targetFolderPath) async {
    final entity = await AssetEntity.fromId(assetId);
    if (entity == null) return false;

    try {
      final albums = await listAlbums();
      final targetAlbum = albums
          .where((a) => a.id == targetFolderPath)
          .firstOrNull;
      if (targetAlbum != null) {
        if (Platform.isAndroid) {
          await PhotoManager.editor.android.moveAssetToAnother(
            entity: entity,
            target: targetAlbum,
          );
          return true;
        }
      }
    } catch (_) {}

    try {
      final file = await entity.file;
      if (file != null && await file.exists()) {
        final targetDir = Directory(targetFolderPath);
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }
        final destPath = p.join(targetFolderPath, p.basename(file.path));
        await file.rename(destPath);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<String?> trashAssetOnDisk(String assetId) async {
    final entity = await AssetEntity.fromId(assetId);
    if (entity == null) return null;
    try {
      final file = await entity.file;
      if (file != null && await file.exists()) {
        final originalPath = file.path;
        final dir = p.dirname(originalPath);
        final name = p.basename(originalPath);
        final newPath = p.join(dir, '.trashed_$name');

        await file.rename(newPath);

        try {
          await PhotoManager.editor.deleteWithIds([assetId]);
        } catch (_) {}

        return originalPath;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> restoreAssetOnDisk(String originalPath) async {
    try {
      final dir = p.dirname(originalPath);
      final name = p.basename(originalPath);
      final trashedPath = p.join(dir, '.trashed_$name');

      final trashedFile = File(trashedPath);
      if (await trashedFile.exists()) {
        await trashedFile.rename(originalPath);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> deleteTrashedFile(String originalPath) async {
    try {
      final dir = p.dirname(originalPath);
      final name = p.basename(originalPath);
      final trashedPath = p.join(dir, '.trashed_$name');

      final trashedFile = File(trashedPath);
      if (await trashedFile.exists()) {
        await trashedFile.delete();
        return true;
      }
    } catch (_) {}
    return false;
  }
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
