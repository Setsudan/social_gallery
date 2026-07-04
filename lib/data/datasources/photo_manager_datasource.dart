import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:photo_manager/photo_manager.dart';
import 'package:social_gallery/core/exif/exif_reader.dart';
import 'package:social_gallery/core/media/asset_media_loader.dart';
import 'package:social_gallery/core/media/filesystem_image_loader.dart';
import 'package:social_gallery/core/sync/gallery_sync_progress.dart';
import 'package:social_gallery/core/media/asset_media_kind.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';
import 'package:social_gallery/data/local/app_database.dart';
import 'package:social_gallery/data/repositories/preferences_repository.dart';

/// Reads device albums and media via photo_manager (mobile) or filesystem (desktop).
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

  Future<List<MediaItemsCompanion>> _loadAllMediaWindows({
    bool Function()? shouldCancel,
    GallerySyncProgressCallback? onProgress,
  }) async {
    final root = _preferences.desktopGalleryRootPath;
    if (root == null || root.isEmpty) return [];

    final files = _scanMediaFiles(root);
    final companions = <MediaItemsCompanion>[];
    final total = files.length;

    onProgress?.call(
      GallerySyncProgress(
        phase: 'scanning',
        detail: 'Scanning $total files',
        processed: 0,
        total: total,
      ),
    );

    var processed = 0;
    for (final file in files) {
      if (shouldCancel?.call() == true) break;
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
        int? width;
        int? height;
        int? dateTaken;
        double? latitude;
        double? longitude;
        String? cameraMake;
        String? cameraModel;
        int? iso;
        String? shutterSpeed;
        double? focalLength;
        String? aperture;

        if (!isVideo) {
          final dimensions = await readFilesystemImageDimensions(filePath);
          width = dimensions?.width;
          height = dimensions?.height;

          dateTaken = await readExifDateTakenMsFromPath(filePath);
          final exifData = await readExifFromPath(filePath);
          if (exifData != null) {
            latitude = exifData.latitude;
            longitude = exifData.longitude;
            cameraMake = exifData.cameraMake;
            cameraModel = exifData.cameraModel;
            iso = exifData.iso;
            shutterSpeed = exifData.shutterSpeed;
            focalLength = exifData.focalLength;
            aperture = exifData.aperture;
          }
        }

        dateTaken ??= dateModified;

        companions.add(
          MediaItemsCompanion.insert(
            id: Value(id),
            uri: filePath,
            displayName: fileName,
            folderName: folderName,
            folderPath: folderPath,
            dateAdded: dateAdded,
            dateModified: dateModified,
            dateTaken: Value(dateTaken),
            size: size,
            mimeType: mimeType,
            width: Value(width),
            height: Value(height),
            latitude: latitude != null ? Value(latitude) : const Value(null),
            longitude: longitude != null ? Value(longitude) : const Value(null),
            cameraMake:
                cameraMake != null ? Value(cameraMake) : const Value(null),
            cameraModel:
                cameraModel != null ? Value(cameraModel) : const Value(null),
            iso: iso != null ? Value(iso) : const Value(null),
            shutterSpeed:
                shutterSpeed != null ? Value(shutterSpeed) : const Value(null),
            focalLength:
                focalLength != null ? Value(focalLength) : const Value(null),
            aperture: aperture != null ? Value(aperture) : const Value(null),
            videoDuration: const Value(null),
          ),
        );
      } catch (_) {}
      processed++;
      if (processed % 25 == 0 || processed == total) {
        onProgress?.call(
          GallerySyncProgress(
            phase: 'scanning',
            detail: 'Scanning files on disk',
            processed: processed,
            total: total,
          ),
        );
      }
    }

    return companions;
  }

  Future<List<FoldersCompanion>> _loadFoldersWindows(
    Map<String, String> existingFollowStatus,
    bool initialSetupComplete,
  ) async {
    final root = _preferences.desktopGalleryRootPath;
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
      final followStatus = existing ??
          (usesFilesystemGallery
              ? 'HOME_FEED'
              : (initialSetupComplete ? 'UNFOLLOWED' : 'HOME_FEED'));

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
    if (usesFilesystemGallery) return [];
    return PhotoManager.getAssetPathList(
      type: RequestType.common,
      hasAll: true,
    );
  }

  Future<List<MediaItemsCompanion>> loadAllMedia({
    bool fastScan = false,
    bool Function()? shouldCancel,
    GallerySyncProgressCallback? onProgress,
  }) async {
    if (usesFilesystemGallery) {
      return _loadAllMediaWindows(
        shouldCancel: shouldCancel,
        onProgress: onProgress,
      );
    }

    final albums = await listAlbums();
    final scanAlbums = albums.where((album) => !album.isAll).toList();
    var totalAssets = 0;
    for (final album in scanAlbums) {
      totalAssets += await album.assetCountAsync;
    }

    onProgress?.call(
      GallerySyncProgress(
        phase: 'scanning',
        detail: 'Found $totalAssets items in ${scanAlbums.length} albums',
        processed: 0,
        total: totalAssets,
      ),
    );

    final companions = <MediaItemsCompanion>[];
    var processed = 0;

    for (final album in scanAlbums) {
      if (shouldCancel?.call() == true) break;

      final count = await album.assetCountAsync;
      if (count == 0) continue;

      onProgress?.call(
        GallerySyncProgress(
          phase: 'scanning',
          detail: 'Scanning ${album.name}',
          processed: processed,
          total: totalAssets,
        ),
      );

      final assets = await album.getAssetListRange(start: 0, end: count);
      final folderPath = album.id;
      final folderName = album.name;

      for (var i = 0; i < assets.length; i++) {
        if (shouldCancel?.call() == true) break;
        if (i % 40 == 0) {
          await Future<void>.delayed(Duration.zero);
        }

        final asset = assets[i];
        final kind = AssetMediaLoader.classify(asset);
        final mimeType = fastScan
            ? AssetMediaLoader.inferMimeTypeSync(asset)
            : await AssetMediaLoader.inferMimeType(asset);

        int size = 0;
        if (!fastScan) {
          final file = await asset.file;
          size = await _assetSize(asset, file?.lengthSync());
        }

        final lat = asset.latitude;
        final lng = asset.longitude;

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
            size: size,
            mimeType: mimeType,
            width: Value(asset.width),
            height: Value(asset.height),
            latitude: lat != null && lat != 0 ? Value(lat) : const Value(null),
            longitude: lng != null && lng != 0 ? Value(lng) : const Value(null),
            videoDuration: Value(
              kind == AssetMediaKind.video ? asset.duration : null,
            ),
          ),
        );

        processed++;
        final reportEvery = math.max(300, totalAssets ~/ 40);
        if (processed % reportEvery == 0 || processed == totalAssets) {
          onProgress?.call(
            GallerySyncProgress(
              phase: 'scanning',
              detail: 'Indexed $processed of $totalAssets items',
              processed: processed,
              total: totalAssets,
            ),
          );
        }
      }
    }

    return companions;
  }

  Future<List<FoldersCompanion>> loadFolders(
    Map<String, String> existingFollowStatus,
    bool initialSetupComplete,
  ) async {
    if (usesFilesystemGallery) {
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
      final coverUri = cover?.id;
      final existing = existingFollowStatus[path];
      final followStatus =
          existing ?? (initialSetupComplete ? 'UNFOLLOWED' : 'HOME_FEED');

      rows.add(
        FoldersCompanion.insert(
          path: path,
          name: album.name,
          mediaCount: Value(count),
          lastModified: Value(DateTime.now().millisecondsSinceEpoch),
          coverImageUri: Value(coverUri),
          followStatus: Value(followStatus),
        ),
      );
    }

    return rows;
  }

  Future<bool> deleteAssets(List<String> assetIds) async {
    if (usesFilesystemGallery) {
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
    if (usesFilesystemGallery) {
      try {
        final root = _preferences.desktopGalleryRootPath;
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
      await Future<void>.delayed(const Duration(milliseconds: 400));
      final albums = await listAlbums();
      final created = albums
          .where((album) => !album.isAll && album.name == folderName)
          .toList();
      if (created.isNotEmpty) {
        return created.first.id;
      }
      return 'Pictures/$folderName';
    } catch (e) {
      debugPrint('createAlbumFolder failed: $e');
      return null;
    }
  }

  Future<String?> resolveTargetAlbumId(String targetFolderPath) async {
    if (usesFilesystemGallery) return targetFolderPath;

    final albums = await listAlbums();
    final byId = albums.where((album) => album.id == targetFolderPath).firstOrNull;
    if (byId != null) return byId.id;

    final relative = _absoluteToRelativePath(targetFolderPath) ?? targetFolderPath;
    for (final album in albums) {
      if (album.isAll) continue;
      final albumRelative = await album.relativePathAsync;
      if (albumRelative == relative) return album.id;
    }

    final name = relative.contains('/')
        ? relative.substring(relative.lastIndexOf('/') + 1)
        : relative;
    final byName = albums
        .where((album) => !album.isAll && album.name == name)
        .firstOrNull;
    return byName?.id;
  }

  /// Moves [assetIds] to [targetFolderPath] and returns the IDs that were
  /// actually moved successfully (a subset of [assetIds], not necessarily a
  /// prefix, since individual assets can fail independently on some
  /// platforms).
  Future<List<String>> moveAssetsOnDisk(
    List<String> assetIds,
    String targetFolderPath,
  ) async {
    if (assetIds.isEmpty) return const [];

    if (usesFilesystemGallery) {
      final movedIds = <String>[];
      for (final assetId in assetIds) {
        if (await moveAssetOnDisk(assetId, targetFolderPath)) {
          movedIds.add(assetId);
        }
      }
      return movedIds;
    }

    final entities = <AssetEntity>[];
    for (final assetId in assetIds) {
      final entity = await AssetEntity.fromId(assetId);
      if (entity != null) entities.add(entity);
    }
    if (entities.isEmpty) return const [];

    final albums = await listAlbums();
    if (Platform.isAndroid) {
      final relativePath = await _resolveAndroidRelativePath(
        targetFolderPath,
        albums,
      );
      if (relativePath == null) {
        debugPrint('moveAssetsOnDisk: could not resolve target path');
        return const [];
      }

      try {
        final moved = await PhotoManager.editor.android.moveAssetsToPath(
          entities: entities,
          targetPath: relativePath,
        );
        if (moved) {
          await PhotoManager.clearFileCache();
          return entities.map((e) => e.id).toList();
        }
      } catch (e) {
        debugPrint('moveAssetsToPath failed: $e');
      }

      if (entities.length == 1) {
        final targetAlbum = albums
            .where((album) => album.id == targetFolderPath)
            .firstOrNull;
        if (targetAlbum != null) {
          try {
            final legacyMoved =
                await PhotoManager.editor.android.moveAssetToAnother(
              entity: entities.first,
              target: targetAlbum,
            );
            if (legacyMoved) {
              await PhotoManager.clearFileCache();
              return [entities.first.id];
            }
          } catch (e) {
            debugPrint('moveAssetToAnother failed: $e');
          }
        }
      }
      return const [];
    }

    if (Platform.isIOS || Platform.isMacOS) {
      final targetAlbum = albums
          .where((album) => album.id == targetFolderPath)
          .firstOrNull;
      if (targetAlbum == null) return const [];

      final movedIds = <String>[];
      for (final entity in entities) {
        try {
          await PhotoManager.editor.copyAssetToPath(
            asset: entity,
            pathEntity: targetAlbum,
          );
          movedIds.add(entity.id);
        } catch (e) {
          debugPrint('copyAssetToPath failed: $e');
        }
      }
      return movedIds;
    }

    return const [];
  }

  Future<bool> moveAssetOnDisk(String assetId, String targetFolderPath) async {
    if (usesFilesystemGallery) {
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
      } catch (e) {
        debugPrint('moveAssetOnDisk windows failed: $e');
      }
      return false;
    }

    final moved = await moveAssetsOnDisk([assetId], targetFolderPath);
    return moved.isNotEmpty;
  }

  Future<String?> _resolveAndroidRelativePath(
    String targetFolderPath,
    List<AssetPathEntity> albums,
  ) async {
    final byId = albums.where((album) => album.id == targetFolderPath).firstOrNull;
    if (byId != null) {
      return await byId.relativePathAsync ?? _albumNameToRelativePath(byId.name);
    }

    final absoluteRelative = _absoluteToRelativePath(targetFolderPath);
    if (absoluteRelative != null) return absoluteRelative;

    if (!targetFolderPath.startsWith('/') && targetFolderPath.contains('/')) {
      return targetFolderPath;
    }

    final name = targetFolderPath.contains('/')
        ? targetFolderPath.substring(targetFolderPath.lastIndexOf('/') + 1)
        : targetFolderPath;
    final byName = albums
        .where((album) => !album.isAll && album.name == name)
        .firstOrNull;
    if (byName != null) {
      return await byName.relativePathAsync ?? _albumNameToRelativePath(name);
    }

    return _albumNameToRelativePath(name);
  }

  String? _absoluteToRelativePath(String path) {
    const markers = ['Pictures/', 'DCIM/', 'Download/'];
    for (final marker in markers) {
      final index = path.indexOf(marker);
      if (index >= 0) {
        return path.substring(index);
      }
    }
    return null;
  }

  String _albumNameToRelativePath(String albumName) => 'Pictures/$albumName';

  Future<String?> trashAssetOnDisk(String assetId) async {
    if (usesFilesystemGallery) {
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
    if (usesFilesystemGallery) {
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
    if (usesFilesystemGallery) {
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
