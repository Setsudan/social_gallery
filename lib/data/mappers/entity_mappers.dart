import 'package:drift/drift.dart';
import 'package:social_gallery/data/local/app_database.dart';
import 'package:social_gallery/domain/models/folder_info.dart';
import 'package:social_gallery/domain/models/follow_status.dart';
import 'package:social_gallery/domain/models/media_item.dart' as domain;

domain.MediaItem mediaItemFromRow(MediaRow row) {
  return domain.MediaItem(
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
  );
}

domain.MediaItem mediaItemFromQueryRow(QueryRow row) {
  return domain.MediaItem(
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
  );
}

FolderInfo folderFromRow(Folder row) {
  return FolderInfo(
    path: row.path,
    name: row.name,
    mediaCount: row.mediaCount,
    coverImageUri: row.coverImageUri,
    followStatus: FollowStatus.fromStorage(row.followStatus),
    showInStories: row.showInStories,
    isBiometricLocked: row.isBiometricLocked,
    biography: row.biography,
  );
}
