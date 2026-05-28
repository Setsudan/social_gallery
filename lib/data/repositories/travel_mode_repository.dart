import 'package:drift/drift.dart';
import 'package:social_gallery/data/local/app_database.dart';
import 'package:social_gallery/domain/models/travel_mode.dart' as domain;

class TravelModeRepository {
  TravelModeRepository(this._db);

  final AppDatabase _db;

  Stream<List<domain.TravelMode>> watchAll() {
    return _db.watchAllTravelModes().map((rows) => rows.map(_fromRow).toList());
  }

  Stream<domain.TravelMode?> watchActive() {
    return _db.watchActiveTravelMode().map(
      (row) => row == null ? null : _fromRow(row),
    );
  }

  Future<domain.TravelMode?> getById(String id) async {
    final row = await _db.getTravelModeById(id);
    return row == null ? null : _fromRow(row);
  }

  Future<void> create(domain.TravelMode mode) {
    return _db.insertTravelMode(_toCompanion(mode));
  }

  Future<void> update(domain.TravelMode mode) {
    return _db.updateTravelMode(_toCompanion(mode));
  }

  Future<void> delete(String id) {
    return _db.deleteTravelMode(id);
  }

  domain.TravelMode _fromRow(TravelMode row) {
    return domain.TravelMode(
      id: row.id,
      name: row.name,
      startDate: row.startDate,
      endDate: row.endDate,
      startTime: row.startTime,
      endTime: row.endTime,
      folderPath: row.folderPath,
      createdAt: row.createdAt,
      notificationEndingSoonHours: row.notificationEndingSoonHours,
    );
  }

  TravelModesCompanion _toCompanion(domain.TravelMode mode) {
    return TravelModesCompanion(
      id: Value(mode.id),
      name: Value(mode.name),
      startDate: Value(mode.startDate),
      endDate: Value(mode.endDate),
      startTime: Value(mode.startTime),
      endTime: Value(mode.endTime),
      folderPath: Value(mode.folderPath),
      createdAt: Value(mode.createdAt),
      notificationEndingSoonHours: Value(mode.notificationEndingSoonHours),
    );
  }
}
