import 'package:social_gallery/domain/models/media_item.dart';

/// In-memory checksum cache for a single backup [run] session.
class BackupSessionChecksumCache {
  final Map<int, ({String checksum, int size, int dateModified})> _entries = {};

  void put(MediaItem item, String checksum) {
    _entries[item.id] = (
      checksum: checksum,
      size: item.size,
      dateModified: item.dateModified,
    );
  }

  String? lookup(MediaItem item) {
    final entry = _entries[item.id];
    if (entry == null) return null;
    if (entry.size != item.size || entry.dateModified != item.dateModified) {
      return null;
    }
    return entry.checksum;
  }

  void clear() => _entries.clear();
}

/// Result of [DesktopBackupClient.initBackup] for one media item.
class BackupUploadSession {
  const BackupUploadSession({
    required this.sessionId,
    required this.alreadyExists,
  });

  final String sessionId;
  final bool alreadyExists;
}
