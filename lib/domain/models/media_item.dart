import 'package:social_gallery/domain/models/backup_state.dart';

/// Indexed photo or video row mirrored from the device library.
class MediaItem {
  const MediaItem({
    required this.id,
    required this.uri,
    required this.displayName,
    required this.folderName,
    required this.folderPath,
    required this.dateAdded,
    required this.dateModified,
    this.dateTaken,
    required this.size,
    required this.mimeType,
    this.width,
    this.height,
    this.latitude,
    this.longitude,
    this.cameraMake,
    this.cameraModel,
    this.iso,
    this.shutterSpeed,
    this.focalLength,
    this.aperture,
    this.isFavorite = false,
    this.videoDuration,
    this.isTrashed = false,
    this.trashedAt,
    this.originalPath,
    this.backupState = MediaBackupState.pending,
    this.lastSyncTime,
    this.isVault = false,
  });

  final int id;
  final String uri;
  final String displayName;
  final String folderName;
  final String folderPath;
  final int dateAdded;
  final int dateModified;
  final int? dateTaken;
  final int size;
  final String mimeType;
  final int? width;
  final int? height;
  final double? latitude;
  final double? longitude;
  final String? cameraMake;
  final String? cameraModel;
  final int? iso;
  final String? shutterSpeed;
  final double? focalLength;
  final String? aperture;
  final bool isFavorite;
  final int? videoDuration;
  final bool isTrashed;
  final int? trashedAt;
  final String? originalPath;
  final MediaBackupState backupState;
  final int? lastSyncTime;
  final bool isVault;

  bool get isVideo => mimeType.startsWith('video/');

  int get sortDate => dateTaken ?? dateModified;

  int get pixelCount => (width ?? 0) * (height ?? 0);

  bool get hasLocation =>
      latitude != null &&
      longitude != null &&
      latitude != 0 &&
      longitude != 0;

  MediaItem copyWith({
    bool? isFavorite,
    bool? isTrashed,
    int? trashedAt,
    String? originalPath,
    String? folderName,
    String? folderPath,
    MediaBackupState? backupState,
    int? lastSyncTime,
    bool? isVault,
  }) {
    return MediaItem(
      id: id,
      uri: uri,
      displayName: displayName,
      folderName: folderName ?? this.folderName,
      folderPath: folderPath ?? this.folderPath,
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
      isFavorite: isFavorite ?? this.isFavorite,
      videoDuration: videoDuration,
      isTrashed: isTrashed ?? this.isTrashed,
      trashedAt: trashedAt ?? this.trashedAt,
      originalPath: originalPath ?? this.originalPath,
      backupState: backupState ?? this.backupState,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      isVault: isVault ?? this.isVault,
    );
  }
}
