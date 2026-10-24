import 'package:social_gallery/data/local/app_database.dart';
import 'package:social_gallery/data/repositories/media_repository.dart';

/// Local Drift-backed inventory of cloud objects.
class CloudBackupInventory {
  CloudBackupInventory(this._media);

  final MediaRepository _media;

  Future<CloudBackupObject?> lookup(int mediaId) =>
      _media.getCloudBackupObject(mediaId);

  Future<void> upsert({
    required int mediaId,
    required String objectKey,
    required String plaintextChecksum,
    required int size,
  }) {
    return _media.upsertCloudBackupObject(
      mediaId: mediaId,
      objectKey: objectKey,
      plaintextChecksum: plaintextChecksum,
      size: size,
    );
  }

  Future<List<CloudBackupObject>> list({int limit = 200, int offset = 0}) {
    return _media.listCloudBackupObjects(limit: limit, offset: offset);
  }

  Future<void> clear() => _media.clearCloudBackupInventory();
}
