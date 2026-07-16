import 'package:social_gallery/domain/models/media_content_kind.dart';

/// Heuristics for screenshot vs photo vs document classification.
class ContentKindClassifier {
  ContentKindClassifier._();

  static const documentLabels = {
    'document',
    'paper',
    'text',
    'receipt',
    'screenshot',
  };

  /// Characters-per-megapixel above which OCR suggests a document.
  static const documentOcrDensityThreshold = 80.0;

  static bool looksLikeScreenshot({
    required String displayName,
    required String folderName,
    required String folderPath,
  }) {
    final name = displayName.toLowerCase();
    final folder = folderName.toLowerCase();
    final path = folderPath.toLowerCase();
    return name.contains('screenshot') ||
        folder.contains('screenshot') ||
        path.contains('screenshot') ||
        name.startsWith('screen') ||
        folder == 'screenshots' ||
        folder == 'screen shots';
  }

  static MediaContentKind classifyAtSync({
    required String displayName,
    required String folderName,
    required String folderPath,
    required bool isVideo,
  }) {
    if (isVideo) return MediaContentKind.photo;
    if (looksLikeScreenshot(
      displayName: displayName,
      folderName: folderName,
      folderPath: folderPath,
    )) {
      return MediaContentKind.screenshot;
    }
    return MediaContentKind.photo;
  }

  static bool looksLikeDocumentFromOcr({
    required String ocrText,
    required int? width,
    required int? height,
    List<String> labels = const [],
  }) {
    final trimmed = ocrText.trim();
    if (trimmed.isEmpty) return false;

    final w = width ?? 0;
    final h = height ?? 0;
    final megapixels = w > 0 && h > 0 ? (w * h) / 1e6 : 1.0;
    final density = trimmed.length / megapixels;
    if (density >= documentOcrDensityThreshold) return true;

    final lowerLabels = labels.map((l) => l.toLowerCase()).toSet();
    if (lowerLabels.intersection(documentLabels).isNotEmpty &&
        trimmed.length >= 40) {
      return true;
    }
    return false;
  }
}
