import 'dart:math';

import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/domain/models/organize_models.dart';

/// Builds the next organize swipe batch from the full media pool.
///
/// Excludes already-processed and pending-trash items so the queue stays
/// consistent with [OrganizeRepository] persistence in SharedPreferences.
class BuildOrganizeQueue {
  /// Returns up to [batchSize] items matching [filter], ordered per [order].
  List<MediaItem> call({
    required List<MediaItem> pool,
    required Set<int> processedIds,
    required Set<int> pendingTrashIds,
    required OrganizeFilter filter,
    required OrganizeQueueOrder order,
    required int batchSize,
  }) {
    final filtered = pool.where((item) {
      if (processedIds.contains(item.id)) return false;
      if (pendingTrashIds.contains(item.id)) return false;
      if (filter.folderPath != null && item.folderPath != filter.folderPath) {
        return false;
      }
      if (filter.mediaType == OrganizeMediaType.image && item.isVideo) {
        return false;
      }
      if (filter.mediaType == OrganizeMediaType.video && !item.isVideo) {
        return false;
      }
      if (filter.month != null) {
        final date = DateTime.fromMillisecondsSinceEpoch(item.sortDate);
        final monthKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}';
        if (monthKey != filter.month) return false;
      }
      return true;
    }).toList();

    if (order == OrganizeQueueOrder.random) {
      filtered.shuffle(Random());
    } else {
      filtered.sort((a, b) => a.sortDate.compareTo(b.sortDate));
    }

    return filtered.take(batchSize).toList();
  }

  /// Count of items still eligible for organize under the current filter.
  int countRemaining({
    required List<MediaItem> pool,
    required Set<int> processedIds,
    required Set<int> pendingTrashIds,
    required OrganizeFilter filter,
  }) {
    return pool.where((item) {
      if (processedIds.contains(item.id)) return false;
      if (pendingTrashIds.contains(item.id)) return false;
      if (filter.folderPath != null && item.folderPath != filter.folderPath) {
        return false;
      }
      if (filter.mediaType == OrganizeMediaType.image && item.isVideo) {
        return false;
      }
      if (filter.mediaType == OrganizeMediaType.video && !item.isVideo) {
        return false;
      }
      if (filter.month != null) {
        final date = DateTime.fromMillisecondsSinceEpoch(item.sortDate);
        final monthKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}';
        if (monthKey != filter.month) return false;
      }
      return true;
    }).length;
  }
}
