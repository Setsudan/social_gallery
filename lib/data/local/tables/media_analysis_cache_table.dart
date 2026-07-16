import 'package:drift/drift.dart';

/// Drift table for cached ML and perceptual-hash analysis per media ID.
@DataClassName('MediaAnalysisRow')
class MediaAnalysisCache extends Table {
  IntColumn get mediaId => integer()();
  TextColumn get dHash => text().nullable()();
  RealColumn get blurScore => real().nullable()();
  RealColumn get exposureScore => real().nullable()();
  BoolColumn get isSolidColor =>
      boolean().withDefault(const Constant(false))();
  IntColumn get faceCount => integer().withDefault(const Constant(0))();
  BoolColumn get hasClosedEyes =>
      boolean().withDefault(const Constant(false))();
  TextColumn get labelsJson => text().nullable()();
  TextColumn get dominantColor => text().nullable()();
  IntColumn get scannedAt => integer()();
  TextColumn get ocrText => text().nullable()();
  IntColumn get ocrScannedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {mediaId};
}
