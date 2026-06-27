import 'package:social_gallery/core/analysis/perceptual_hash.dart';
import 'package:social_gallery/domain/models/media_analysis_result.dart';
import 'package:social_gallery/domain/models/media_item.dart';

class FindSimilarGroups {
  static const timeWindowMs = 2 * 60 * 1000;

  List<SimilarPhotoGroup> call({
    required List<MediaItem> items,
    required Map<int, MediaAnalysisResult> analysisById,
  }) {
    final images = items.where((i) => !i.isVideo).toList()
      ..sort((a, b) => a.sortDate.compareTo(b.sortDate));

    final groups = <List<int>>[];
    final used = <int>{};

    for (var i = 0; i < images.length; i++) {
      final a = images[i];
      if (used.contains(a.id)) continue;
      final hashA = analysisById[a.id]?.dHash;
      if (hashA == null || hashA.isEmpty) continue;

      final group = <int>[a.id];
      used.add(a.id);

      for (var j = i + 1; j < images.length; j++) {
        final b = images[j];
        if (used.contains(b.id)) continue;
        if ((b.sortDate - a.sortDate).abs() > timeWindowMs) break;

        final hashB = analysisById[b.id]?.dHash;
        if (hashB == null || hashB.isEmpty) continue;
        if (hammingDistance(hashA, hashB) <= similarHammingThreshold) {
          group.add(b.id);
          used.add(b.id);
        }
      }

      if (group.length > 1) {
        groups.add(group);
      }
    }

    return groups.asMap().entries.map((entry) {
      final ids = entry.value;
      final rep = ids.first;
      return SimilarPhotoGroup(
        id: 'similar_${entry.key}',
        mediaIds: ids,
        representativeId: rep,
      );
    }).toList();
  }
}
