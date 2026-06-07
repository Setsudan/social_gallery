import 'dart:io';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:photo_manager/photo_manager.dart';
import 'package:social_gallery/core/exif/exif_reader.dart';
import 'package:social_gallery/core/media/asset_media_loader.dart';
import 'package:social_gallery/core/media/asset_media_kind.dart';
import 'package:social_gallery/data/local/app_database.dart';
import 'package:social_gallery/data/repositories/preferences_repository.dart';

class PhotoManagerDatasource {
  final PreferencesRepository _preferences;
  PhotoManagerDatasource(this._preferences);
  static const _imageExtensions = {
    'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic', 'heif', 'tif', 'tiff'
  };
  static const _videoExtensions = {
    'mp4', 'mov', 'm4v', 'avi', 'mkv', 'webm', '3gp', 'mpeg', 'mpg', 'wmv', 'flv'
  };
  static final _supportedExtensions = {..._imageExtensions, ..._videoExtensions};

  List<File> _scanMediaFiles(String rootPath) {
    final dir = Directory(rootPath);
    if (!dir.existsSync()) return [];
    
    final files = <File>[];
    try {
      final list = dir.listSync(recursive: true, followLinks: false);
      for (final entity in list) {
        if (entity is File) {
          final name = p.basename(entity.path);
          if (name.startsWith('.trashed_')) continue; // Skip trashed files
          final ext = p.extension(entity.path).replaceAll('.', '').toLowerCase();
          if (_supportedExtensions.contains(ext)) {
            files.add(entity);
          }
        }
      }
    } catch (_) {}
    return files;
  }

  Future<List<MediaItemsCompanion>> _loadAllMediaWindows() async {
    final root = _preferences.windowsGalleryRootPath;
    if (root == null || root.isEmpty) return [];

    final files = _scanMediaFiles(root);
    final companions = <MediaItemsCompanion>[];

    for (final file in files) {
      final filePath = file.path;
      final fileName = p.basename(filePath);
      final folderPath = p.dirname(filePath);
      final folderName = p.basename(folderPath);

      try {
        final stat = file.statSync();
        final size = stat.size;
        final dateModified = stat.modified.millisecondsSinceEpoch;
        final dateAdded = stat.changed.millisecondsSinceEpoch;

        final ext = p.extension(filePath).replaceAll('.', '').toLowerCase();
        final isVideo = _videoExtensions.contains(ext);
        final mimeType = isVideo ? 'video/mp4' : 'image/jpeg';

        final id = filePath.hashCode & 0x7FFFFFFF;

        companions.add(
          MediaItemsCompanion.insert(
            id: Value(id),
            uri: filePath,
            displayName: fileName,
            folderName: folderName,
            folderPath: folderPath,
            dateAdded: dateAdded,
            dateModified: dateModified,
            dateTaken: Value(dateModified),
            size: size,
            mimeType: mimeType,
            width: const Value(null),
            height: const Value(null),
            videoDuration: const Value(null),
          ),
        );
      } catch (_) {}
    }

    return companions;
  }

  Future<List<FoldersCompanion>> _loadFoldersWindows(
    Map<String, String> existingFollowStatus,
    bool initialSetupComplete,
  ) async {
    final root = _preferences.windowsGalleryRootPath;
    if (root == null || root.isEmpty) return [];

    final files = _scanMediaFiles(root);
    final folderMap = <String, List<File>>{};

    for (final file in files) {
      final folderPath = p.dirname(file.path);
      folderMap.putIfAbsent(folderPath, () => []).add(file);
    }

    final folderRows = <FoldersCompanion>[];

    for (final entry in folderMap.entries) {
      final path = entry.key;
      final folderFiles = entry.value;
      final count = folderFiles.length;

      final coverFile = folderFiles.firstWhere(
        (f) => _imageExtensions.contains(p.extension(f.path).replaceAll('.', '').toLowerCase()),
        orElse: () => folderFiles.first,
      );

      final existing = existingFollowStatus[path];
      final followStatus =
          existing ?? (initialSetupComplete ? 'UNFOLLOWED' : 'HOME_FEED');

      folderRows.add(
        FoldersCompanion.insert(
          path: path,
          name: p.basename(path),
          mediaCount: Value(count),
          lastModified: Value(DateTime.now().millisecondsSinceEpoch),
          coverImageUri: Value(coverFile.path),
          followStatus: Value(followStatus),
        ),
      );
    }

    return folderRows;
  }

  Future<List<AssetPathEntity>> listAlbums() async {
    if (Platform.isWindows) return [];
    return PhotoManager.getAssetPathList(
      type: RequestType.common,
      hasAll: true,
    );
  }

  Future<List<MediaItemsCompanion>> loadAllMedia() async {
    if (Platform.isWindows) {
      return _loadAllMediaWindows();
    }
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
        final exif = kind == AssetMediaKind.image
            ? await readExifFromPath(file?.path)
            : null;
        final lat = asset.latitude ?? exif?.latitude;
        final lng = asset.longitude ?? exif?.longitude;
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
            latitude: lat != null && lat != 0 ? Value(lat) : const Value(null),
            longitude: lng != null && lng != 0 ? Value(lng) : const Value(null),
            cameraMake: Value(exif?.cameraMake),
            cameraModel: Value(exif?.cameraModel),
            iso: Value(exif?.iso),
            shutterSpeed: Value(exif?.shutterSpeed),
            focalLength: Value(exif?.focalLength),
            aperture: Value(exif?.aperture),
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
    if (Platform.isWindows) {
      return _loadFoldersWindows(existingFollowStatus, initialSetupComplete);
    }
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
    if (Platform.isWindows) {
      for (final id in assetIds) {
        try {
          final file = File(id);
          if (file.existsSync()) {
            file.deleteSync();
          }
        } catch (_) {}
      }
      return true;
    }
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
    if (Platform.isWindows) {
      try {
        final root = _preferences.windowsGalleryRootPath;
        if (root == null || root.isEmpty) return null;
        final newFolder = Directory(p.join(root, folderName));
        if (!newFolder.existsSync()) {
          newFolder.createSync(recursive: true);
        }
        return newFolder.path;
      } catch (_) {
        return null;
      }
    }
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
    if (Platform.isWindows) {
      try {
        final file = File(assetId);
        if (file.existsSync()) {
          final destDir = Directory(targetFolderPath);
          if (!destDir.existsSync()) {
            destDir.createSync(recursive: true);
          }
          final destPath = p.join(targetFolderPath, p.basename(assetId));
          file.renameSync(destPath);
          return true;
        }
      } catch (_) {}
      return false;
    }
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
    if (Platform.isWindows) {
      try {
        final file = File(assetId);
        if (file.existsSync()) {
          final originalPath = file.path;
          final dir = p.dirname(originalPath);
          final name = p.basename(originalPath);
          final newPath = p.join(dir, '.trashed_$name');
          file.renameSync(newPath);
          return originalPath;
        }
      } catch (_) {}
      return null;
    }
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
    if (Platform.isWindows) {
      try {
        final dir = p.dirname(originalPath);
        final name = p.basename(originalPath);
        final trashedPath = p.join(dir, '.trashed_$name');

        final trashedFile = File(trashedPath);
        if (trashedFile.existsSync()) {
          trashedFile.renameSync(originalPath);
          return true;
        }
      } catch (_) {}
      return false;
    }
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
    if (Platform.isWindows) {
      try {
        final dir = p.dirname(originalPath);
        final name = p.basename(originalPath);
        final trashedPath = p.join(dir, '.trashed_$name');

        final trashedFile = File(trashedPath);
        if (trashedFile.existsSync()) {
          trashedFile.deleteSync();
          return true;
        }
      } catch (_) {}
      return false;
    }
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
