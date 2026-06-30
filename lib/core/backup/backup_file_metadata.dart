import 'dart:io';

/// Metadata sent with each backed-up file and applied on the desktop receiver.
class BackupFileMetadata {
  const BackupFileMetadata({
    this.dateTaken,
    this.dateModified,
    this.dateAdded,
    this.latitude,
    this.longitude,
  });

  factory BackupFileMetadata.fromInitJson(Map<String, dynamic> json) {
    return BackupFileMetadata(
      dateTaken: json['dateTaken'] as int?,
      dateModified: json['dateModified'] as int?,
      dateAdded: json['dateAdded'] as int?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  final int? dateTaken;
  final int? dateModified;
  final int? dateAdded;
  final double? latitude;
  final double? longitude;

  bool get hasTimestamps =>
      dateTaken != null || dateModified != null || dateAdded != null;
}

/// Applies captured-at timestamps to a backed-up file on disk.
Future<void> applyBackupFileMetadata(
  String path,
  BackupFileMetadata metadata,
) async {
  if (!metadata.hasTimestamps) {
    return;
  }

  final file = File(path);
  if (!file.existsSync()) {
    return;
  }

  final sortMs = metadata.dateTaken ?? metadata.dateModified;
  if (sortMs != null) {
    final capturedAt = DateTime.fromMillisecondsSinceEpoch(sortMs);
    await file.setLastModified(capturedAt);
  }

  final addedMs = metadata.dateAdded;
  if (addedMs != null && addedMs != sortMs) {
    try {
      await file.setLastAccessed(
        DateTime.fromMillisecondsSinceEpoch(addedMs),
      );
    } catch (_) {
      // setLastAccessed is not supported on all platforms.
    }
  }
}
