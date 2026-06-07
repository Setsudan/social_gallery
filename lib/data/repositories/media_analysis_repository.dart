import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:social_gallery/data/local/app_database.dart';
import 'package:social_gallery/domain/models/media_analysis_result.dart';

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
    await _db.upsertAnalysisRow(_toCompanion(result));
  }

  Future<void> saveResults(List<MediaAnalysisResult> results) async {
    await _db.upsertAnalysisRows(results.map(_toCompanion).toList());
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
      scannedAt: Value(result.scannedAt),
    );
  }
}
