import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:social_gallery/core/analysis/image_metrics.dart';
import 'package:social_gallery/domain/models/media_analysis_result.dart';
import 'package:social_gallery/domain/models/media_item.dart';

class MediaAnalysisProgress {
  const MediaAnalysisProgress({
    required this.scanned,
    required this.total,
    this.currentId,
  });

  final int scanned;
  final int total;
  final int? currentId;

  double get fraction => total == 0 ? 0 : scanned / total;
}

class MediaAnalysisService {
  bool get mlAvailable =>
      !kIsWeb &&
      (Platform.isAndroid || Platform.isIOS);

  Future<MediaAnalysisResult?> analyzeItem(
    MediaItem item, {
    Uint8List? thumbnailBytes,
  }) async {
    if (item.isVideo) return null;

    final bytes = thumbnailBytes ?? await _loadThumbnailBytes(item);
    if (bytes == null || bytes.isEmpty) return null;

    final dHash = computeDHash(bytes);
    final blurScore = computeBlurScore(bytes);
    final exposureScore = computeExposureScore(bytes);
    final isSolidColor = computeIsSolidColor(bytes);

    var faceCount = 0;
    var hasClosedEyes = false;
    final labels = <String>[];

    if (mlAvailable) {
      final ml = await _runMlKit(item, bytes);
      faceCount = ml.faceCount;
      hasClosedEyes = ml.hasClosedEyes;
      labels.addAll(ml.labels);
    }

    return MediaAnalysisResult(
      mediaId: item.id,
      dHash: dHash.isEmpty ? null : dHash,
      blurScore: blurScore,
      exposureScore: exposureScore,
      isSolidColor: isSolidColor,
      faceCount: faceCount,
      hasClosedEyes: hasClosedEyes,
      labels: labels,
      scannedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Stream<MediaAnalysisProgress> scanLibrary({
    required List<MediaItem> items,
    required Set<int> alreadyScanned,
    void Function(MediaAnalysisResult result)? onResult,
  }) async* {
    final images = items.where((i) => !i.isVideo).toList();
    final total = images.length;
    var scanned = 0;

    for (final item in images) {
      if (alreadyScanned.contains(item.id)) {
        scanned++;
        yield MediaAnalysisProgress(
          scanned: scanned,
          total: total,
          currentId: item.id,
        );
        continue;
      }

      final result = await analyzeItem(item);
      if (result != null) {
        onResult?.call(result);
      }
      scanned++;
      yield MediaAnalysisProgress(
        scanned: scanned,
        total: total,
        currentId: item.id,
      );
    }
  }

  Future<Uint8List?> _loadThumbnailBytes(MediaItem item) async {
    try {
      if (Platform.isWindows) {
        final file = File(item.uri);
        if (file.existsSync()) {
          return file.readAsBytes();
        }
        return null;
      }
      final entity = await AssetEntity.fromId(item.uri);
      if (entity == null) return null;
      final data = await entity.thumbnailDataWithSize(
        const ThumbnailSize(256, 256),
      );
      return data;
    } catch (_) {
      return null;
    }
  }

  Future<({int faceCount, bool hasClosedEyes, List<String> labels})> _runMlKit(
    MediaItem item,
    Uint8List bytes,
  ) async {
    var faceCount = 0;
    var hasClosedEyes = false;
    final labels = <String>[];

    try {
      final tempDir = Directory.systemTemp;
      final tempFile = File(
        '${tempDir.path}/sg_analysis_${item.id}.jpg',
      );
      await tempFile.writeAsBytes(bytes);
      final inputImage = InputImage.fromFilePath(tempFile.path);

      final labeler = ImageLabeler(
        options: ImageLabelerOptions(confidenceThreshold: 0.6),
      );
      final labelResults = await labeler.processImage(inputImage);
      labels.addAll(
        labelResults.take(3).map((e) => e.label),
      );
      await labeler.close();

      final faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: true,
          performanceMode: FaceDetectorMode.fast,
        ),
      );
      final faces = await faceDetector.processImage(inputImage);
      faceCount = faces.length;
      hasClosedEyes = faces.any(
        (f) =>
            f.leftEyeOpenProbability != null &&
            f.rightEyeOpenProbability != null &&
            f.leftEyeOpenProbability! < 0.3 &&
            f.rightEyeOpenProbability! < 0.3,
      );
      await faceDetector.close();

      try {
        await tempFile.delete();
      } catch (_) {}
    } catch (_) {}

    return (
      faceCount: faceCount,
      hasClosedEyes: hasClosedEyes,
      labels: labels,
    );
  }
}
