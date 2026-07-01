import 'package:drift/drift.dart';
import 'package:social_gallery/data/local/app_database.dart';
import 'package:social_gallery/domain/models/resolved_place.dart';

/// Read/write cache for reverse-geocoded place data.
class LocationRepository {
  LocationRepository(this._db);

  final AppDatabase _db;

  Future<ResolvedPlace?> getCachedPlace(String placeKey) async {
    final row = await _db.getCachedPlace(placeKey);
    return row == null ? null : _fromRow(row);
  }

  Future<Map<String, ResolvedPlace>> getAllCachedPlaces() async {
    final rows = await _db.getAllCachedPlaces();
    return {for (final row in rows) row.placeKey: _fromRow(row)};
  }

  Future<void> upsertPlace(ResolvedPlace place) async {
    await _db.upsertPlace(_toCompanion(place));
  }

  ResolvedPlace _fromRow(LocationPlaceRow row) {
    return ResolvedPlace(
      placeKey: row.placeKey,
      latitude: row.latitude,
      longitude: row.longitude,
      countryCode: row.countryCode,
      countryName: row.countryName,
      locality: row.locality,
      adminArea: row.adminArea,
      geocodedAt: row.geocodedAt,
    );
  }

  LocationPlaceCacheCompanion _toCompanion(ResolvedPlace place) {
    return LocationPlaceCacheCompanion(
      placeKey: Value(place.placeKey),
      latitude: Value(place.latitude),
      longitude: Value(place.longitude),
      countryCode: Value(place.countryCode),
      countryName: Value(place.countryName),
      locality: Value(place.locality),
      adminArea: Value(place.adminArea),
      geocodedAt: Value(place.geocodedAt),
    );
  }
}
