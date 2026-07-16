import 'dart:async';
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

  List<AssetPathEntity>? _albumsCache;
  DateTime? _albumsCacheAt;
  static const _albumsCacheTtl = Duration(seconds: 30);
  final _resolvedAlbumIds = <String, String>{};

  List<File> _scanMediaFiles(String rootPath, {bool newestFirst = true}) {
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

    if (newestFirst && files.length > 1) {
      files.sort((a, b) {
        try {
          return b.statSync().modified.compareTo(a.statSync().modified);
        } catch (_) {
          return 0;
        }
      });
    }
    return files;
  }

  static const _syncChunkSize = 200;

  Future<void> _scanAllMediaWindows({
    bool Function()? shouldCancel,
    GallerySyncProgressCallback? onProgress,
    required Future<void> Function(List<MediaItemsCompanion> chunk) onChunk,
  }) async {
    final root = _preferences.desktopGalleryRootPath;
    if (root == null || root.isEmpty) return;

    final files = _scanMediaFiles(root);
    final chunk = <MediaItemsCompanion>[];
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

        chunk.add(
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
      if (chunk.length >= _syncChunkSize) {
        await onChunk(List<MediaItemsCompanion>.from(chunk));
        chunk.clear();
      }
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
    if (chunk.isNotEmpty) {
      await onChunk(chunk);
    }
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

  Future<List<AssetPathEntity>> listAlbumsCached({
    Duration maxAge = _albumsCacheTtl,
  }) async {
    if (usesFilesystemGallery) return const [];
    final cached = _albumsCache;
    final cachedAt = _albumsCacheAt;
    if (cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < maxAge) {
      return cached;
    }
    final albums = await listAlbums();
    _albumsCache = albums;
    _albumsCacheAt = DateTime.now();
    return albums;
  }

  void invalidateAlbumsCache() {
    _albumsCache = null;
    _albumsCacheAt = null;
    _resolvedAlbumIds.clear();
  }

  void _deferClearFileCache() {
    unawaited(
      Future<void>(() async {
        try {
          await PhotoManager.clearFileCache();
        } catch (_) {}
      }),
    );
  }

  /// Scans the device library and delivers companions in bounded chunks.
  Future<void> scanAllMedia({
    bool fastScan = false,
    bool Function()? shouldCancel,
    GallerySyncProgressCallback? onProgress,
    required Future<void> Function(List<MediaItemsCompanion> chunk) onChunk,
  }) async {
    if (usesFilesystemGallery) {
      await _scanAllMediaWindows(
        shouldCancel: shouldCancel,
        onProgress: onProgress,
        onChunk: onChunk,
      );
      return;
    }

    final albums = await listAlbums();
    final unsorted = albums.where((album) => !album.isAll).toList();
    var totalAssets = 0;
    for (final album in unsorted) {
      totalAssets += await album.assetCountAsync;
    }

    onProgress?.call(
      GallerySyncProgress(
        phase: 'scanning',
        detail: 'Found $totalAssets items in ${unsorted.length} albums',
        processed: 0,
        total: totalAssets,
      ),
    );

    // Newest albums first so gallery/home update with recent media early.
    final scanAlbums = await _albumsNewestFirst(unsorted, shouldCancel);

    final chunk = <MediaItemsCompanion>[];
    var processed = 0;

    Future<void> flushChunk() async {
      if (chunk.isEmpty) return;
      await onChunk(List<MediaItemsCompanion>.from(chunk));
      chunk.clear();
    }

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

      final folderPath = album.id;
      final folderName = album.name;

      for (var start = 0; start < count; start += _syncChunkSize) {
        if (shouldCancel?.call() == true) break;
        final end = math.min(start + _syncChunkSize, count);
        final assets = await album.getAssetListRange(start: start, end: end);

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

          chunk.add(
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
              longitude:
                  lng != null && lng != 0 ? Value(lng) : const Value(null),
              videoDuration: Value(
                kind == AssetMediaKind.video ? asset.duration : null,
              ),
            ),
          );

          processed++;
          if (chunk.length >= _syncChunkSize) {
            await flushChunk();
          }
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
    }

    await flushChunk();
  }

  /// Orders albums by newest asset first so sync surfaces recent media early.
  Future<List<AssetPathEntity>> _albumsNewestFirst(
    List<AssetPathEntity> albums,
    bool Function()? shouldCancel,
  ) async {
    if (albums.length <= 1) return albums;

    final scored = <({AssetPathEntity album, int newestMs})>[];
    for (final album in albums) {
      if (shouldCancel?.call() == true) break;
      try {
        final count = await album.assetCountAsync;
        if (count == 0) {
          scored.add((album: album, newestMs: 0));
          continue;
        }
        final newest = await album.getAssetListRange(start: 0, end: 1);
        final ms =
            newest.firstOrNull?.modifiedDateTime.millisecondsSinceEpoch ?? 0;
        scored.add((album: album, newestMs: ms));
      } catch (_) {
        scored.add((album: album, newestMs: 0));
      }
    }

    scored.sort((a, b) => b.newestMs.compareTo(a.newestMs));
    return scored.map((e) => e.album).toList();
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

    final cached = _resolvedAlbumIds[targetFolderPath];
    if (cached != null) return cached;

    final albums = await listAlbumsCached();
    final byId =
        albums.where((album) => album.id == targetFolderPath).firstOrNull;
    if (byId != null) {
      _resolvedAlbumIds[targetFolderPath] = byId.id;
      return byId.id;
    }

    final relative =
        _absoluteToRelativePath(targetFolderPath) ?? targetFolderPath;
    for (final album in albums) {
      if (album.isAll) continue;
      final albumRelative = await album.relativePathAsync;
      if (albumRelative == relative) {
        _resolvedAlbumIds[targetFolderPath] = album.id;
        return album.id;
      }
    }

    final name = relative.contains('/')
        ? relative.substring(relative.lastIndexOf('/') + 1)
        : relative;
    final byName = albums
        .where((album) => !album.isAll && album.name == name)
        .firstOrNull;
    final resolved = byName?.id;
    if (resolved != null) {
      _resolvedAlbumIds[targetFolderPath] = resolved;
    }
    return resolved;
  }

  /// Moves [assetIds] to [targetFolderPath].
  ///
  /// Returns a map of old asset id/path → new asset id/path for each success.
  /// On mobile the id is usually unchanged; on filesystem gallery the path
  /// (and therefore the id) changes after rename.
  Future<Map<String, String>> moveAssetsOnDisk(
    List<String> assetIds,
    String targetFolderPath,
  ) async {
    if (assetIds.isEmpty) return const {};

    if (usesFilesystemGallery) {
      final moved = <String, String>{};
      for (final assetId in assetIds) {
        final newPath = await moveFilesystemAsset(assetId, targetFolderPath);
        if (newPath != null) {
          moved[assetId] = newPath;
        }
      }
      return moved;
    }

    final entities = <AssetEntity>[];
    for (final assetId in assetIds) {
      final entity = await AssetEntity.fromId(assetId);
      if (entity != null) entities.add(entity);
    }
    if (entities.isEmpty) return const {};

    final albums = await listAlbumsCached();
    if (Platform.isAndroid) {
      final relativePath = await _resolveAndroidRelativePath(
        targetFolderPath,
        albums,
      );
      if (relativePath == null) {
        debugPrint('moveAssetsOnDisk: could not resolve target path');
        return const {};
      }

      try {
        final moved = await PhotoManager.editor.android.moveAssetsToPath(
          entities: entities,
          targetPath: relativePath,
        );
        if (moved) {
          invalidateAlbumsCache();
          _deferClearFileCache();
          return {for (final e in entities) e.id: e.id};
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
              invalidateAlbumsCache();
              _deferClearFileCache();
              return {entities.first.id: entities.first.id};
            }
          } catch (e) {
            debugPrint('moveAssetToAnother failed: $e');
          }
        }
      }
      return const {};
    }

    if (Platform.isIOS || Platform.isMacOS) {
      final targetAlbum = albums
          .where((album) => album.id == targetFolderPath)
          .firstOrNull;
      if (targetAlbum == null) return const {};

      final moved = <String, String>{};
      for (final entity in entities) {
        try {
          await PhotoManager.editor.copyAssetToPath(
            asset: entity,
            pathEntity: targetAlbum,
          );
          moved[entity.id] = entity.id;
        } catch (e) {
          debugPrint('copyAssetToPath failed: $e');
        }
      }
      if (moved.isNotEmpty) {
        invalidateAlbumsCache();
      }
      return moved;
    }

    return const {};
  }

  /// Renames a filesystem gallery file into [targetFolderPath].
  /// Returns the destination path on success.
  Future<String?> moveFilesystemAsset(
    String assetPath,
    String targetFolderPath,
  ) async {
    try {
      final file = File(assetPath);
      if (!file.existsSync()) return null;
      final destDir = Directory(targetFolderPath);
      if (!destDir.existsSync()) {
        destDir.createSync(recursive: true);
      }
      var destPath = p.join(targetFolderPath, p.basename(assetPath));
      if (destPath == assetPath) return assetPath;
      if (File(destPath).existsSync()) {
        final stem = p.basenameWithoutExtension(assetPath);
        final ext = p.extension(assetPath);
        destPath = p.join(
          targetFolderPath,
          '${stem}_${DateTime.now().millisecondsSinceEpoch}$ext',
        );
      }
      file.renameSync(destPath);
      return destPath;
    } catch (e) {
      debugPrint('moveFilesystemAsset failed: $e');
      return null;
    }
  }

  Future<bool> moveAssetOnDisk(String assetId, String targetFolderPath) async {
    if (usesFilesystemGallery) {
      final moved = await moveFilesystemAsset(assetId, targetFolderPath);
      return moved != null;
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
