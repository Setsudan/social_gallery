/// Cached on-device analysis for one image (dHash, blur, exposure, faces).
class MediaAnalysisResult {
  const MediaAnalysisResult({
    required this.mediaId,
    this.dHash,
    this.blurScore,
    this.exposureScore,
    this.isSolidColor = false,
    this.faceCount = 0,
    this.hasClosedEyes = false,
    this.labels = const [],
    this.dominantColor,
    required this.scannedAt,
  });

  final int mediaId;
  final String? dHash;
  final double? blurScore;
  final double? exposureScore;
  final bool isSolidColor;
  final int faceCount;
  final bool hasClosedEyes;
  final List<String> labels;
  final String? dominantColor;
  final int scannedAt;

  bool get isFullyTaggedForSearch =>
      dominantColor != null && dominantColor!.isNotEmpty;
}

/// Burst-like cluster from [FindSimilarGroups]; [representativeId] is the suggested keeper.
class SimilarPhotoGroup {
  const SimilarPhotoGroup({
    required this.id,
    required this.mediaIds,
    required this.representativeId,
  });

  final String id;
  final List<int> mediaIds;
  final int representativeId;

  int get count => mediaIds.length;
}

/// One image flagged by [ScoreLowQuality] with human-readable [reasons].
class LowQualityItem {
  const LowQualityItem({
    required this.mediaId,
    required this.reasons,
  });

  final int mediaId;
  final List<String> reasons;
}

/// Monthly or all-time shooting summary from [ComputeShootingStats].
class ShootingStats {
  const ShootingStats({
    this.photoCount = 0,
    this.videoCount = 0,
    this.screenshotCount = 0,
    this.likedCount = 0,
    this.folderCount = 0,
    this.totalVideoDurationMs = 0,
    this.dailyCounts = const {},
    this.mostActiveDay,
    this.mostActiveDayCount = 0,
  });

  final int photoCount;
  final int videoCount;
  final int screenshotCount;
  final int likedCount;
  final int folderCount;
  final int totalVideoDurationMs;
  final Map<String, int> dailyCounts;
  final String? mostActiveDay;
  final int mostActiveDayCount;
}

/// Aggregate counts shown on the Discover hub (organize, duplicates, analysis).
class DiscoverHubData {
  const DiscoverHubData({
    this.duplicateGroupCount = 0,
    this.duplicateItemCount = 0,
    this.similarGroupCount = 0,
    this.lowQualityCount = 0,
    this.unprocessedCount = 0,
    this.pendingTrashCount = 0,
    this.likedCount = 0,
    this.processedCount = 0,
    this.geotaggedCount = 0,
    this.isLoading = true,
  });

  final int duplicateGroupCount;
  final int duplicateItemCount;
  final int similarGroupCount;
  final int lowQualityCount;
  final int unprocessedCount;
  final int pendingTrashCount;
  final int likedCount;
  final int processedCount;
  final int geotaggedCount;
  final bool isLoading;
}
