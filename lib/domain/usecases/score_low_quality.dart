import 'package:social_gallery/domain/models/media_analysis_result.dart';
import 'package:social_gallery/domain/models/media_item.dart';

/// Flags images that fail resolution, size, blur, or exposure thresholds from analysis cache.
class ScoreLowQuality {
  static const blurThreshold = 80.0;
  static const darkThreshold = 40.0;
  static const brightThreshold = 220.0;
  static const minPixels = 500 * 500;
  static const minFileSize = 50 * 1024;

  List<LowQualityItem> call({
    required List<MediaItem> items,
    required Map<int, MediaAnalysisResult> analysisById,
  }) {
    final results = <LowQualityItem>[];

    for (final item in items) {
      if (item.isVideo) continue;
      final analysis = analysisById[item.id];
      final reasons = <String>[];

      if ((item.pixelCount) > 0 && item.pixelCount < minPixels) {
        reasons.add('Low resolution');
      }
      if (item.size < minFileSize) {
        reasons.add('Small file');
      }
      if (analysis?.isSolidColor == true) {
        reasons.add('Solid color');
      }
      if (analysis?.blurScore != null &&
          analysis!.blurScore! < blurThreshold) {
        reasons.add('Blurry');
      }
      if (analysis?.exposureScore != null) {
        if (analysis!.exposureScore! < darkThreshold) {
          reasons.add('Underexposed');
        } else if (analysis.exposureScore! > brightThreshold) {
          reasons.add('Overexposed');
        }
      }
      if (analysis?.hasClosedEyes == true) {
        reasons.add('Closed eyes');
      }

      if (reasons.isNotEmpty) {
        results.add(LowQualityItem(mediaId: item.id, reasons: reasons));
      }
    }

    return results;
  }
}
