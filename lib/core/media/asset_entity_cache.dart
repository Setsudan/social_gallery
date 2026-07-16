import 'package:photo_manager/photo_manager.dart';

/// Session cache for [AssetEntity.fromId] so grid tiles do not re-fetch on rebuild.
class AssetEntityCache {
  AssetEntityCache._();

  static const int maxEntries = 256;

  static final Map<String, Future<AssetEntity?>> _cache = {};
  static final List<String> _order = [];

  static Future<AssetEntity?> resolve(String assetId) {
    final existing = _cache[assetId];
    if (existing != null) {
      _order.remove(assetId);
      _order.add(assetId);
      return existing;
    }

    final future = AssetEntity.fromId(assetId);
    _cache[assetId] = future;
    _order.add(assetId);
    _evictIfNeeded();
    return future;
  }

  static void _evictIfNeeded() {
    while (_order.length > maxEntries) {
      final oldest = _order.removeAt(0);
      _cache.remove(oldest);
    }
  }

  static void evict(String assetId) {
    _cache.remove(assetId);
    _order.remove(assetId);
  }

  static void clear() {
    _cache.clear();
    _order.clear();
  }
}
