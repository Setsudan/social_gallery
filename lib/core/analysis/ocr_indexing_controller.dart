import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/media/content_kind_classifier.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';
import 'package:social_gallery/domain/models/media_analysis_result.dart';
import 'package:social_gallery/domain/models/media_content_kind.dart';
import 'package:social_gallery/domain/models/media_item.dart';

class OcrIndexingScanState {
  const OcrIndexingScanState({
    this.isScanning = false,
    this.scanned = 0,
    this.total = 0,
    this.error,
  });

  final bool isScanning;
  final int scanned;
  final int total;
  final String? error;

  double get progress => total == 0 ? 0 : scanned / total;
}

/// Incremental on-device OCR indexing for Explore text search and documents.
class OcrIndexingController extends StateNotifier<OcrIndexingScanState> {
  OcrIndexingController(this._ref) : super(const OcrIndexingScanState());

  final Ref _ref;
  static const _maxOcrChars = 4000;

  bool get isAvailable =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> startScan() async {
    if (state.isScanning) return;
    if (!isAvailable) {
      state = const OcrIndexingScanState(
        error: 'OCR is only available on Android and iOS',
      );
      return;
    }

    state = const OcrIndexingScanState(isScanning: true);

    try {
      final mediaRepo = _ref.read(mediaRepositoryProvider);
      final analysisRepo = _ref.read(mediaAnalysisRepositoryProvider);

      final items = await mediaRepo.getAllSearchableMedia();
      final cached = await analysisRepo.getAllCached();
      final photos = items.where((item) => !item.isVideo).toList();
      final pending = photos
          .where((item) => !(cached[item.id]?.hasOcr ?? false))
          .toList();

      state = OcrIndexingScanState(
        isScanning: true,
        total: pending.length,
      );

      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      var scanned = 0;

      try {
        for (final item in pending) {
          final existing = cached[item.id];
          final ocrText = await _recognize(recognizer, item);
          final now = DateTime.now().millisecondsSinceEpoch;
          final truncated = ocrText == null || ocrText.isEmpty
              ? ''
              : (ocrText.length > _maxOcrChars
                  ? ocrText.substring(0, _maxOcrChars)
                  : ocrText);

          final result = (existing ??
                  MediaAnalysisResult(
                    mediaId: item.id,
                    scannedAt: now,
                  ))
              .copyWith(
                ocrText: truncated.isEmpty ? null : truncated,
                ocrScannedAt: now,
              );
          await analysisRepo.saveResult(result);

          if (truncated.isNotEmpty &&
              ContentKindClassifier.looksLikeDocumentFromOcr(
                ocrText: truncated,
                width: item.width,
                height: item.height,
                labels: result.labels,
              ) &&
              item.contentKind != MediaContentKind.screenshot) {
            await mediaRepo.updateContentKind(
              item.id,
              MediaContentKind.document,
            );
          }

          scanned++;
          state = OcrIndexingScanState(
            isScanning: true,
            scanned: scanned,
            total: pending.length,
          );
        }
      } finally {
        await recognizer.close();
      }

      state = OcrIndexingScanState(
        isScanning: false,
        scanned: pending.length,
        total: pending.length,
      );
    } catch (e) {
      state = OcrIndexingScanState(
        isScanning: false,
        error: e.toString(),
      );
    }
  }

  Future<String?> _recognize(
    TextRecognizer recognizer,
    MediaItem item,
  ) async {
    try {
      File? tempFile;
      String path;

      if (usesFilesystemGallery) {
        path = item.uri;
        if (!File(path).existsSync()) return null;
      } else {
        final entity = await AssetEntity.fromId(item.uri);
        if (entity == null) return null;
        final file = await entity.file;
        if (file == null) {
          final bytes = await entity.thumbnailDataWithSize(
            const ThumbnailSize(1024, 1024),
          );
          if (bytes == null || bytes.isEmpty) return null;
          tempFile = File(
            '${Directory.systemTemp.path}/sg_ocr_${item.id}.jpg',
          );
          await tempFile.writeAsBytes(bytes);
          path = tempFile.path;
        } else {
          path = file.path;
        }
      }

      final input = InputImage.fromFilePath(path);
      final recognized = await recognizer.processImage(input);
      try {
        await tempFile?.delete();
      } catch (_) {}
      return recognized.text.trim();
    } catch (_) {
      return null;
    }
  }
}

final ocrIndexingProvider =
    StateNotifierProvider<OcrIndexingController, OcrIndexingScanState>(
  (ref) => OcrIndexingController(ref),
);
