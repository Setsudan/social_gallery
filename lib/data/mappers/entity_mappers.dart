import 'package:drift/drift.dart';
import 'package:social_gallery/data/local/app_database.dart';
import 'package:social_gallery/domain/models/folder_info.dart';
import 'package:social_gallery/domain/models/follow_status.dart';
import 'package:social_gallery/domain/models/backup_state.dart';
import 'package:social_gallery/domain/models/media_item.dart' as domain;

domain.MediaItem _mediaItemFromFields({
  required int id,
  required String uri,
  required String displayName,
  required String folderName,
  required String folderPath,
  required int dateAdded,
  required int dateModified,
  required int? dateTaken,
  required int size,
  required String mimeType,
  required int? width,
  required int? height,
  required double? latitude,
  required double? longitude,
  required String? cameraMake,
  required String? cameraModel,
  required int? iso,
  required String? shutterSpeed,
  required double? focalLength,
  required String? aperture,
  required bool isFavorite,
  required int? videoDuration,
  required bool isTrashed,
  required int? trashedAt,
  required String? originalPath,
  MediaBackupState backupState = MediaBackupState.pending,
  int? lastSyncTime,
}) {
  return domain.MediaItem(
    id: id,
    uri: uri,
    displayName: displayName,
    folderName: folderName,
    folderPath: folderPath,
    dateAdded: dateAdded,
    dateModified: dateModified,
    dateTaken: dateTaken,
    size: size,
    mimeType: mimeType,
    width: width,
    height: height,
    latitude: latitude,
    longitude: longitude,
    cameraMake: cameraMake,
    cameraModel: cameraModel,
    iso: iso,
    shutterSpeed: shutterSpeed,
    focalLength: focalLength,
    aperture: aperture,
    isFavorite: isFavorite,
    videoDuration: videoDuration,
    isTrashed: isTrashed,
    trashedAt: trashedAt,
    originalPath: originalPath,
    backupState: backupState,
    lastSyncTime: lastSyncTime,
  );
}

/// Maps a [MediaRow] Drift row to the domain [MediaItem] model.
domain.MediaItem mediaItemFromRow(MediaRow row) {
  return _mediaItemFromFields(
    id: row.id,
    uri: row.uri,
    displayName: row.displayName,
    folderName: row.folderName,
    folderPath: row.folderPath,
    dateAdded: row.dateAdded,
    dateModified: row.dateModified,
    dateTaken: row.dateTaken,
    size: row.size,
    mimeType: row.mimeType,
    width: row.width,
    height: row.height,
    latitude: row.latitude,
    longitude: row.longitude,
    cameraMake: row.cameraMake,
    cameraModel: row.cameraModel,
    iso: row.iso,
    shutterSpeed: row.shutterSpeed,
    focalLength: row.focalLength,
    aperture: row.aperture,
    isFavorite: row.isFavorite,
    videoDuration: row.videoDuration,
    isTrashed: row.isTrashed,
    trashedAt: row.trashedAt,
    originalPath: row.originalPath,
    backupState: MediaBackupState.fromValue(row.backupState),
    lastSyncTime: row.lastSyncTime,
  );
}

/// Maps a custom SQL [QueryRow] (snake_case columns) to [MediaItem].
domain.MediaItem mediaItemFromQueryRow(QueryRow row) {
  return _mediaItemFromFields(
    id: row.read<int>('id'),
    uri: row.read<String>('uri'),
    displayName: row.read<String>('display_name'),
    folderName: row.read<String>('folder_name'),
    folderPath: row.read<String>('folder_path'),
    dateAdded: row.read<int>('date_added'),
    dateModified: row.read<int>('date_modified'),
    dateTaken: row.readNullable<int>('date_taken'),
    size: row.read<int>('size'),
    mimeType: row.read<String>('mime_type'),
    width: row.readNullable<int>('width'),
    height: row.readNullable<int>('height'),
    latitude: row.readNullable<double>('latitude'),
    longitude: row.readNullable<double>('longitude'),
    cameraMake: row.readNullable<String>('camera_make'),
    cameraModel: row.readNullable<String>('camera_model'),
    iso: row.readNullable<int>('iso'),
    shutterSpeed: row.readNullable<String>('shutter_speed'),
    focalLength: row.readNullable<double>('focal_length'),
    aperture: row.readNullable<String>('aperture'),
    isFavorite: row.read<bool>('is_favorite'),
    videoDuration: row.readNullable<int>('video_duration'),
    isTrashed: row.read<bool>('is_trashed'),
    trashedAt: row.readNullable<int>('trashed_at'),
    originalPath: row.readNullable<String>('original_path'),
    backupState: MediaBackupState.fromValue(row.read<int>('backup_state')),
    lastSyncTime: row.readNullable<int>('last_sync_time'),
  );
}

/// Maps a [Folder] Drift row to the domain [FolderInfo] model.
FolderInfo folderFromRow(Folder row) {
  return FolderInfo(
    path: row.path,
    name: row.name,
    mediaCount: row.mediaCount,
    coverImageUri: row.coverImageUri,
    customCoverUri: row.customCoverUri,
    followStatus: FollowStatus.fromStorage(row.followStatus),
    showInStories: row.showInStories,
    isBiometricLocked: row.isBiometricLocked,
    biography: row.biography,
  );
}
