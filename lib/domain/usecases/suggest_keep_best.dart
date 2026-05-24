import 'package:social_gallery/domain/models/media_item.dart';

class SuggestKeepBest {
  MediaItem call(List<MediaItem> items) {
    final sorted = [...items]..sort((a, b) {
        final dateCmp = b.sortDate.compareTo(a.sortDate);
        if (dateCmp != 0) return dateCmp;
        final sizeCmp = b.size.compareTo(a.size);
        if (sizeCmp != 0) return sizeCmp;
        return b.pixelCount.compareTo(a.pixelCount);
      });
    return sorted.first;
  }

  Set<int> idsToRemove(List<MediaItem> items) {
    final keeper = call(items);
    return items.where((m) => m.id != keeper.id).map((m) => m.id).toSet();
  }
}
