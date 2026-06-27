import 'package:social_gallery/core/analysis/perceptual_hash.dart';
import 'package:social_gallery/domain/models/duplicate_group.dart';
import 'package:social_gallery/domain/models/media_item.dart';

class FindDuplicateGroups {
  List<DuplicateGroup> call({
    required List<MediaItem> candidates,
    required Map<int, String> hashesById,
  }) {
    final buckets = <String, List<MediaItem>>{};
    for (final item in candidates) {
      if (item.isVideo) continue;
      if (!hashesById.containsKey(item.id)) continue;

      final key = '${item.size}_${item.width ?? -1}_${item.height ?? -1}';
      buckets.putIfAbsent(key, () => []).add(item);
    }

    final groups = <DuplicateGroup>[];
    var groupIndex = 0;

    for (final bucket in buckets.values) {
      if (bucket.length < 2) continue;

      for (final cluster in _clusterBucket(bucket, hashesById)) {
        groups.add(
          DuplicateGroup(
            id: 'dup_${groupIndex++}_${cluster.first.id}',
            items: cluster
              ..sort((a, b) => a.sortDate.compareTo(b.sortDate)),
          ),
        );
      }
    }

    return groups..sort((a, b) => b.count.compareTo(a.count));
  }

  List<List<MediaItem>> _clusterBucket(
    List<MediaItem> bucket,
    Map<int, String> hashesById,
  ) {
    final parent = <int, int>{};

    int find(int id) {
      parent.putIfAbsent(id, () => id);
      if (parent[id] != id) {
        parent[id] = find(parent[id]!);
      }
      return parent[id]!;
    }

    void union(int a, int b) {
      final rootA = find(a);
      final rootB = find(b);
      if (rootA != rootB) {
        parent[rootB] = rootA;
      }
    }

    for (var i = 0; i < bucket.length; i++) {
      final hashA = hashesById[bucket[i].id]!;
      for (var j = i + 1; j < bucket.length; j++) {
        final hashB = hashesById[bucket[j].id]!;
        if (hammingDistance(hashA, hashB) <= duplicateHammingThreshold) {
          union(bucket[i].id, bucket[j].id);
        }
      }
    }

    final clusters = <int, List<MediaItem>>{};
    for (final item in bucket) {
      final root = find(item.id);
      clusters.putIfAbsent(root, () => []).add(item);
    }

    return clusters.values.where((cluster) => cluster.length > 1).toList();
  }
}
