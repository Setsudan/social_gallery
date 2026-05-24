import 'package:social_gallery/domain/models/duplicate_group.dart';
import 'package:social_gallery/domain/models/media_item.dart';

class FindDuplicateGroups {
  List<DuplicateGroup> call(List<MediaItem> candidates) {
    final grouped = <String, List<MediaItem>>{};
    for (final item in candidates) {
      final key = '${item.size}_${item.width ?? -1}_${item.height ?? -1}';
      grouped.putIfAbsent(key, () => []).add(item);
    }

    return grouped.entries
        .where((e) => e.value.length > 1)
        .map(
          (e) => DuplicateGroup(
            size: e.value.first.size,
            width: e.value.first.width,
            height: e.value.first.height,
            items: e.value,
          ),
        )
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
  }
}
