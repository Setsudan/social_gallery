import 'package:photo_manager/photo_manager.dart';

/// Session cache for [AssetEntity.fromId] so grid tiles do not re-fetch on rebuild.
class AssetEntityCache {
  AssetEntityCache._();

  static const int maxEntries = 768;

  static final Map<String, Future<AssetEntity?>> _futures = {};
  static final Map<String, AssetEntity?> _resolved = {};
  static final List<String> _order = [];

  /// Synchronously returns a previously resolved entity, if any.
  ///
  /// Used by grid tiles to skip [FutureBuilder] placeholder frames when the
  /// entity was already warmed by prefetch or a prior visit.
  static AssetEntity? peek(String assetId) {
    if (!_resolved.containsKey(assetId)) return null;
    _touch(assetId);
    return _resolved[assetId];
  }

  static Future<AssetEntity?> resolve(String assetId) {
    final existing = _futures[assetId];
    if (existing != null) {
      _touch(assetId);
      return existing;
    }

    final future = AssetEntity.fromId(assetId).then((entity) {
      _resolved[assetId] = entity;
      return entity;
    });
    _futures[assetId] = future;
    _order.add(assetId);
    _evictIfNeeded();
    return future;
  }

  static void _touch(String assetId) {
    _order.remove(assetId);
    _order.add(assetId);
  }

  static void _evictIfNeeded() {
    while (_order.length > maxEntries) {
      final oldest = _order.removeAt(0);
      _futures.remove(oldest);
      _resolved.remove(oldest);
    }
  }

  static void evict(String assetId) {
    _futures.remove(assetId);
    _resolved.remove(assetId);
    _order.remove(assetId);
  }

  static void clear() {
    _futures.clear();
    _resolved.clear();
    _order.clear();
  }
}
