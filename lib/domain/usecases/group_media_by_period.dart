import 'package:intl/intl.dart';
import 'package:social_gallery/domain/models/gallery_grouping_period.dart';
import 'package:social_gallery/domain/models/media_item.dart';

/// One labeled section in the gallery timeline (day, month, or year).
class MediaPeriodGroup {
  const MediaPeriodGroup({
    required this.key,
    required this.label,
    required this.items,
  });

  final String key;
  final String label;
  final List<MediaItem> items;
}

/// Groups gallery media into day/month/year sections for pinch-to-zoom timeline UI.
class GroupMediaByPeriod {
  List<MediaPeriodGroup> call({
    required List<MediaItem> items,
    required GalleryGroupingPeriod period,
  }) {
    if (items.isEmpty) return const [];

    final sorted = [...items]..sort((a, b) => b.sortDate.compareTo(a.sortDate));
    final grouped = <String, List<MediaItem>>{};

    for (final item in sorted) {
      final date = DateTime.fromMillisecondsSinceEpoch(item.sortDate);
      final key = _groupKey(date, period);
      grouped.putIfAbsent(key, () => []).add(item);
    }

    final keys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return keys.map((key) {
      final groupItems = grouped[key]!;
      final date = DateTime.fromMillisecondsSinceEpoch(groupItems.first.sortDate);
      return MediaPeriodGroup(
        key: key,
        label: _groupLabel(date, period),
        items: groupItems,
      );
    }).toList();
  }

  String _groupKey(DateTime date, GalleryGroupingPeriod period) {
    switch (period) {
      case GalleryGroupingPeriod.day:
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      case GalleryGroupingPeriod.month:
        return '${date.year}-${date.month.toString().padLeft(2, '0')}';
      case GalleryGroupingPeriod.year:
        return '${date.year}';
    }
  }

  String _groupLabel(DateTime date, GalleryGroupingPeriod period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDay = DateTime(date.year, date.month, date.day);

    switch (period) {
      case GalleryGroupingPeriod.day:
        if (itemDay == today) return 'Today';
        if (itemDay == today.subtract(const Duration(days: 1))) {
          return 'Yesterday';
        }
        return DateFormat('EEEE, MMMM d, y').format(date);
      case GalleryGroupingPeriod.month:
        return DateFormat('MMMM y').format(date);
      case GalleryGroupingPeriod.year:
        return DateFormat('y').format(date);
    }
  }
}
