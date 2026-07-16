import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:social_gallery/data/local/app_database.dart';
import 'package:social_gallery/domain/models/media_analysis_result.dart';

/// Read/write cache for ML and perceptual-hash analysis results.
class MediaAnalysisRepository {
  MediaAnalysisRepository(this._db);

  final AppDatabase _db;

  Future<Map<int, MediaAnalysisResult>> getAllCached() async {
    final rows = await _db.getAllAnalysisRows();
    return {for (final row in rows) row.mediaId: _fromRow(row)};
  }

  Future<MediaAnalysisResult?> getForMedia(int mediaId) async {
    final row = await _db.getAnalysisForMedia(mediaId);
    return row == null ? null : _fromRow(row);
  }

  Future<void> saveResult(MediaAnalysisResult result) async {
    final existing = await getForMedia(result.mediaId);
    final merged = existing == null
        ? result
        : result.copyWith(
            ocrText: result.ocrText ?? existing.ocrText,
            ocrScannedAt: result.ocrScannedAt ?? existing.ocrScannedAt,
            // Prefer newer labels/colors from [result]; keep OCR from either.
          );
    // If OCR pass omitted labels, keep prior labels/hash metrics.
    final finalResult = existing != null &&
            result.dHash == null &&
            result.ocrScannedAt != null
        ? existing.copyWith(
            ocrText: result.ocrText,
            ocrScannedAt: result.ocrScannedAt,
          )
        : merged;
    await _db.upsertAnalysisRow(_toCompanion(finalResult));
  }

  Future<void> saveResults(List<MediaAnalysisResult> results) async {
    for (final result in results) {
      await saveResult(result);
    }
  }

  Future<int> getCachedCount() => _db.getAnalysisCount();

  MediaAnalysisResult _fromRow(MediaAnalysisRow row) {
    List<String> labels = [];
    if (row.labelsJson != null && row.labelsJson!.isNotEmpty) {
      try {
        labels = (jsonDecode(row.labelsJson!) as List<dynamic>)
            .map((e) => e.toString())
            .toList();
      } catch (_) {}
    }
    return MediaAnalysisResult(
      mediaId: row.mediaId,
      dHash: row.dHash,
      blurScore: row.blurScore,
      exposureScore: row.exposureScore,
      isSolidColor: row.isSolidColor,
      faceCount: row.faceCount,
      hasClosedEyes: row.hasClosedEyes,
      labels: labels,
      dominantColor: row.dominantColor,
      ocrText: row.ocrText,
      ocrScannedAt: row.ocrScannedAt,
      scannedAt: row.scannedAt,
    );
  }

  MediaAnalysisCacheCompanion _toCompanion(MediaAnalysisResult result) {
    return MediaAnalysisCacheCompanion(
      mediaId: Value(result.mediaId),
      dHash: Value(result.dHash),
      blurScore: Value(result.blurScore),
      exposureScore: Value(result.exposureScore),
      isSolidColor: Value(result.isSolidColor),
      faceCount: Value(result.faceCount),
      hasClosedEyes: Value(result.hasClosedEyes),
      labelsJson: Value(
        result.labels.isEmpty ? null : jsonEncode(result.labels),
      ),
      dominantColor: Value(result.dominantColor),
      ocrText: Value(result.ocrText),
      ocrScannedAt: Value(result.ocrScannedAt),
      scannedAt: Value(result.scannedAt),
    );
  }
}
