import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_gallery/domain/models/organize_models.dart';

/// Persists organize session state in SharedPreferences (processed IDs, filters, stats).
class OrganizeRepository {
  OrganizeRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _processedKey = 'organize_processed_ids';
  static const _pendingTrashKey = 'organize_pending_trash_ids';
  static const _statsKey = 'organize_stats';
  static const _batchSizeKey = 'organize_batch_size';
  static const _queueOrderKey = 'organize_queue_order';
  static const _filterFolderKey = 'organize_filter_folder';
  static const _filterTypeKey = 'organize_filter_type';
  static const _filterMonthKey = 'organize_filter_month';
  static const _hapticsKey = 'organize_haptics_enabled';
  static const _recentFoldersKey = 'organize_recent_folders';
  static const _maxRecentFolders = 30;

  Set<int> get processedIds => _readIntSet(_processedKey);
  Set<int> get pendingTrashIds => _readIntSet(_pendingTrashKey);

  OrganizeStats get stats {
    final raw = _prefs.getString(_statsKey);
    if (raw == null) return const OrganizeStats();
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return OrganizeStats(
        processedCount: map['processed'] as int? ?? 0,
        deletedCount: map['deleted'] as int? ?? 0,
        likedCount: map['liked'] as int? ?? 0,
        savedBytes: map['savedBytes'] as int? ?? 0,
      );
    } catch (_) {
      return const OrganizeStats();
    }
  }

  int get batchSize => _prefs.getInt(_batchSizeKey) ?? 16;
  OrganizeQueueOrder get queueOrder {
    final raw = _prefs.getString(_queueOrderKey) ?? 'random';
    return raw == 'chronological'
        ? OrganizeQueueOrder.chronological
        : OrganizeQueueOrder.random;
  }

  OrganizeFilter get filter => OrganizeFilter(
    folderPath: _prefs.getString(_filterFolderKey),
    mediaType: organizeMediaTypeFromStorage(
      _prefs.getString(_filterTypeKey) ?? 'all',
    ),
    month: _prefs.getString(_filterMonthKey),
  );

  bool get hapticsEnabled => _prefs.getBool(_hapticsKey) ?? true;

  List<String> get recentFolderPaths =>
      _prefs.getStringList(_recentFoldersKey) ?? const [];

  Future<void> recordRecentFolder(String path) async {
    final current = recentFolderPaths.where((p) => p != path).toList();
    final next = [path, ...current].take(_maxRecentFolders).toList();
    await _prefs.setStringList(_recentFoldersKey, next);
  }

  Future<void> addProcessed(int id) async {
    final set = processedIds..add(id);
    await _writeIntSet(_processedKey, set);
  }

  Future<void> removeProcessed(int id) async {
    final set = processedIds..remove(id);
    await _writeIntSet(_processedKey, set);
  }

  Future<void> clearProcessed() async {
    await _prefs.remove(_processedKey);
  }

  Future<void> addPendingTrash(int id) async {
    final set = pendingTrashIds..add(id);
    await _writeIntSet(_pendingTrashKey, set);
  }

  Future<void> removePendingTrash(int id) async {
    final set = pendingTrashIds..remove(id);
    await _writeIntSet(_pendingTrashKey, set);
  }

  Future<void> clearPendingTrash() async {
    await _prefs.remove(_pendingTrashKey);
  }

  Future<void> updateStats(OrganizeStats stats) async {
    await _prefs.setString(
      _statsKey,
      jsonEncode({
        'processed': stats.processedCount,
        'deleted': stats.deletedCount,
        'liked': stats.likedCount,
        'savedBytes': stats.savedBytes,
      }),
    );
  }

  Future<void> setBatchSize(int size) async {
    await _prefs.setInt(_batchSizeKey, size.clamp(10, 30));
  }

  Future<void> setQueueOrder(OrganizeQueueOrder order) async {
    await _prefs.setString(
      _queueOrderKey,
      order == OrganizeQueueOrder.chronological ? 'chronological' : 'random',
    );
  }

  Future<void> setFilter(OrganizeFilter filter) async {
    if (filter.folderPath == null) {
      await _prefs.remove(_filterFolderKey);
    } else {
      await _prefs.setString(_filterFolderKey, filter.folderPath!);
    }
    await _prefs.setString(_filterTypeKey, filter.mediaType.storageValue);
    if (filter.month == null) {
      await _prefs.remove(_filterMonthKey);
    } else {
      await _prefs.setString(_filterMonthKey, filter.month!);
    }
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    await _prefs.setBool(_hapticsKey, enabled);
  }

  Set<int> _readIntSet(String key) {
    final list = _prefs.getStringList(key) ?? [];
    return list.map(int.parse).toSet();
  }

  Future<void> _writeIntSet(String key, Set<int> ids) async {
    await _prefs.setStringList(
      key,
      ids.map((e) => e.toString()).toList(),
    );
  }
}
