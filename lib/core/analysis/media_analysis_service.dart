import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:social_gallery/core/analysis/desktop_image_labeler.dart';
import 'package:social_gallery/core/analysis/image_metrics.dart';
import 'package:social_gallery/core/media/filesystem_image_loader.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';
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

typedef MediaAnalysisNeedsScan =
    bool Function(int mediaId, MediaAnalysisResult? cached);

/// How much on-device ML to run for an item.
enum MediaAnalysisMode {
  /// Metrics, dominant color, and image labels — no face detector.
  tagForSearch,

  /// Full Deep Organize pass including face detection / closed-eyes.
  analyzeFull,
}

class MediaAnalysisService {
  ImageLabeler? _labeler;
  FaceDetector? _faceDetector;
  bool _mlInitFailed = false;

  bool get mlAvailable =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS) && !_mlInitFailed;

  bool get desktopLabelingAvailable =>
      !kIsWeb &&
      usesFilesystemGallery &&
      DesktopImageLabeler.instance.isAvailable;

  static bool needsTaggingScan(int mediaId, MediaAnalysisResult? cached) {
    if (cached == null) return true;
    return !cached.isFullyTaggedForSearch;
  }

  ImageLabeler get _sharedLabeler => _labeler ??= ImageLabeler(
    options: ImageLabelerOptions(confidenceThreshold: 0.55),
  );

  FaceDetector get _sharedFaceDetector => _faceDetector ??= FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  /// Releases long-lived ML Kit instances (call on app pause / dispose).
  Future<void> disposeMl() async {
    final labeler = _labeler;
    final faces = _faceDetector;
    _labeler = null;
    _faceDetector = null;
    try {
      await labeler?.close();
    } catch (_) {}
    try {
      await faces?.close();
    } catch (_) {}
  }

  Future<MediaAnalysisResult?> analyzeItem(
    MediaItem item, {
    Uint8List? thumbnailBytes,
    MediaAnalysisMode mode = MediaAnalysisMode.analyzeFull,
  }) async {
    if (item.isVideo) return null;

    final bytes = thumbnailBytes ?? await _loadThumbnailBytes(item);
    if (bytes == null || bytes.isEmpty) return null;

    final metrics = computeAllImageMetrics(bytes);
    if (metrics == null || metrics.dHash.isEmpty) return null;

    var faceCount = 0;
    var hasClosedEyes = false;
    final labels = <String>[];

    final includeFaces = mode == MediaAnalysisMode.analyzeFull;

    if (mlAvailable) {
      final ml = await _runMlKit(item, bytes, includeFaces: includeFaces);
      faceCount = ml.faceCount;
      hasClosedEyes = ml.hasClosedEyes;
      labels.addAll(ml.labels);
    } else if (desktopLabelingAvailable) {
      final desktopLabels = await DesktopImageLabeler.instance.labelImage(
        bytes,
      );
      labels.addAll(desktopLabels);
    }

    return MediaAnalysisResult(
      mediaId: item.id,
      dHash: metrics.dHash,
      blurScore: metrics.blurScore,
      exposureScore: metrics.exposureScore,
      isSolidColor: metrics.isSolidColor,
      faceCount: faceCount,
      hasClosedEyes: hasClosedEyes,
      labels: mergeNormalizedLabels(labels),
      dominantColor: metrics.dominantColor,
      scannedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Background search indexing: labels + color, no face detector.
  Future<MediaAnalysisResult?> tagForSearch(
    MediaItem item, {
    Uint8List? thumbnailBytes,
  }) {
    return analyzeItem(
      item,
      thumbnailBytes: thumbnailBytes,
      mode: MediaAnalysisMode.tagForSearch,
    );
  }

  Future<String?> computeDHashForItem(
    MediaItem item, {
    Uint8List? thumbnailBytes,
  }) async {
    if (item.isVideo) return null;

    final bytes = thumbnailBytes ?? await _loadThumbnailBytes(item);
    if (bytes == null || bytes.isEmpty) return null;

    final hash = computeDHash(bytes);
    return hash.isEmpty ? null : hash;
  }

  Future<Map<int, String>> ensureDHashesForItems({
    required List<MediaItem> items,
    required Map<int, String?> cachedHashes,
    void Function(int scanned, int total)? onProgress,
  }) async {
    final hashes = <int, String>{};
    for (final entry in cachedHashes.entries) {
      final hash = entry.value;
      if (hash != null && hash.isNotEmpty) {
        hashes[entry.key] = hash;
      }
    }

    final photos = items.where((i) => !i.isVideo).toList();
    final total = photos.length;
    var scanned = 0;

    for (final item in photos) {
      if (hashes.containsKey(item.id)) {
        scanned++;
        onProgress?.call(scanned, total);
        continue;
      }

      final hash = await computeDHashForItem(item);
      if (hash != null) {
        hashes[item.id] = hash;
      }
      scanned++;
      onProgress?.call(scanned, total);
    }

    return hashes;
  }

  Stream<MediaAnalysisProgress> scanLibrary({
    required List<MediaItem> items,
    Map<int, MediaAnalysisResult>? cachedById,
    MediaAnalysisNeedsScan? needsScan,
    void Function(MediaAnalysisResult result)? onResult,
    MediaAnalysisMode mode = MediaAnalysisMode.analyzeFull,
  }) async* {
    final images = items.where((i) => !i.isVideo).toList();
    final total = images.length;
    var scanned = 0;
    final shouldScan = needsScan ?? (_, cached) => cached == null;

    for (final item in images) {
      final cached = cachedById?[item.id];
      if (!shouldScan(item.id, cached)) {
        scanned++;
        yield MediaAnalysisProgress(
          scanned: scanned,
          total: total,
          currentId: item.id,
        );
        continue;
      }

      final result = await analyzeItem(item, mode: mode);
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
      if (usesFilesystemGallery) {
        return await readFilesystemThumbnailBytes(item.uri);
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
    Uint8List bytes, {
    required bool includeFaces,
  }) async {
    var faceCount = 0;
    var hasClosedEyes = false;
    final labels = <String>[];

    try {
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/sg_analysis_${item.id}.jpg');
      await tempFile.writeAsBytes(bytes);
      final inputImage = InputImage.fromFilePath(tempFile.path);

      try {
        final labelResults = await _sharedLabeler.processImage(inputImage);
        labels.addAll(
          labelResults
              .take(8)
              .map((e) => normalizeLabel(e.label))
              .where((label) => label.isNotEmpty),
        );
      } catch (e, st) {
        debugPrint('ML Kit image labeling failed: $e\n$st');
        _mlInitFailed = true;
        await disposeMl();
      }

      if (includeFaces && !_mlInitFailed) {
        try {
          final faces = await _sharedFaceDetector.processImage(inputImage);
          faceCount = faces.length;
          hasClosedEyes = faces.any(
            (f) =>
                f.leftEyeOpenProbability != null &&
                f.rightEyeOpenProbability != null &&
                f.leftEyeOpenProbability! < 0.3 &&
                f.rightEyeOpenProbability! < 0.3,
          );
        } catch (e, st) {
          debugPrint('ML Kit face detection failed: $e\n$st');
        }
      }

      try {
        await tempFile.delete();
      } catch (_) {}
    } catch (e, st) {
      debugPrint('ML Kit analysis setup failed: $e\n$st');
    }

    return (faceCount: faceCount, hasClosedEyes: hasClosedEyes, labels: labels);
  }
}
