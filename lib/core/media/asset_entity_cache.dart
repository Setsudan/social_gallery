import 'package:photo_manager/photo_manager.dart';

/// Session cache for [AssetEntity.fromId] so grid tiles do not re-fetch on rebuild.
class AssetEntityCache {
  AssetEntityCache._();

  static final Map<String, Future<AssetEntity?>> _cache = {};

  static Future<AssetEntity?> resolve(String assetId) {
    return _cache.putIfAbsent(assetId, () => AssetEntity.fromId(assetId));
  }

  static void evict(String assetId) {
    _cache.remove(assetId);
  }

  static void clear() {
    _cache.clear();
  }
}
