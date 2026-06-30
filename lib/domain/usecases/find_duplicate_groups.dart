import 'package:social_gallery/core/analysis/perceptual_hash.dart';
import 'package:social_gallery/domain/models/duplicate_group.dart';
import 'package:social_gallery/domain/models/media_item.dart';

/// Groups near-identical photos by size/dimensions bucket, then Hamming distance on dHash.
class FindDuplicateGroups {
  List<DuplicateGroup> call({
    required List<MediaItem> candidates,
    required Map<int, String> hashesById,
  }) {
    final groups = <DuplicateGroup>[];
    final groupedIds = <int>{};
    var groupIndex = 0;

    void addGroup(List<MediaItem> cluster) {
      if (cluster.length < 2) return;
      final sorted = [...cluster]
        ..sort((a, b) => a.sortDate.compareTo(b.sortDate));
      groups.add(
        DuplicateGroup(
          id: 'dup_${groupIndex++}_${sorted.first.id}',
          items: sorted,
        ),
      );
      groupedIds.addAll(sorted.map((item) => item.id));
    }

    final byExactHash = <String, List<MediaItem>>{};
    for (final item in candidates) {
      if (item.isVideo) continue;
      final hash = hashesById[item.id];
      if (hash == null) continue;
      byExactHash.putIfAbsent(hash, () => []).add(item);
    }
    for (final cluster in byExactHash.values) {
      addGroup(cluster);
    }

    final buckets = <String, List<MediaItem>>{};
    for (final item in candidates) {
      if (item.isVideo || groupedIds.contains(item.id)) continue;
      if (!hashesById.containsKey(item.id)) continue;

      final key = '${item.size}_${item.width ?? -1}_${item.height ?? -1}';
      buckets.putIfAbsent(key, () => []).add(item);
    }

    for (final bucket in buckets.values) {
      if (bucket.length < 2) continue;

      for (final cluster in _clusterBucket(bucket, hashesById)) {
        final unseen =
            cluster.where((item) => !groupedIds.contains(item.id)).toList();
        addGroup(unseen);
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
