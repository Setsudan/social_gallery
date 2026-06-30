import 'package:social_gallery/domain/models/media_analysis_result.dart';
import 'package:social_gallery/domain/models/media_item.dart';

/// Aggregates photo/video counts, favorites, folders, and daily activity for a month.
class ComputeShootingStats {
  ShootingStats call({
    required List<MediaItem> items,
    DateTime? month,
  }) {
    final filtered = items.where((item) {
      if (month == null) return true;
      final date = DateTime.fromMillisecondsSinceEpoch(item.sortDate);
      return date.year == month.year && date.month == month.month;
    }).toList();

    var photos = 0;
    var videos = 0;
    var screenshots = 0;
    var liked = 0;
    var videoDuration = 0;
    final folders = <String>{};
    final daily = <String, int>{};

    for (final item in filtered) {
      folders.add(item.folderPath);
      if (item.isFavorite) liked++;
      if (item.isVideo) {
        videos++;
        videoDuration += item.videoDuration ?? 0;
      } else {
        photos++;
        if (_isScreenshot(item)) screenshots++;
      }

      final date = DateTime.fromMillisecondsSinceEpoch(item.sortDate);
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      daily[key] = (daily[key] ?? 0) + 1;
    }

    String? mostActiveDay;
    var mostActiveCount = 0;
    for (final entry in daily.entries) {
      if (entry.value > mostActiveCount) {
        mostActiveCount = entry.value;
        mostActiveDay = entry.key;
      }
    }

    return ShootingStats(
      photoCount: photos,
      videoCount: videos,
      screenshotCount: screenshots,
      likedCount: liked,
      folderCount: folders.length,
      totalVideoDurationMs: videoDuration,
      dailyCounts: daily,
      mostActiveDay: mostActiveDay,
      mostActiveDayCount: mostActiveCount,
    );
  }

  bool _isScreenshot(MediaItem item) {
    final name = item.displayName.toLowerCase();
    final path = item.folderPath.toLowerCase();
    return name.contains('screenshot') ||
        path.contains('screenshot') ||
        name.startsWith('screen');
  }
}
