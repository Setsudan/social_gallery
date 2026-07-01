import 'package:drift/drift.dart';

/// Cached reverse-geocoding results keyed by rounded coordinate grid cell.
@DataClassName('LocationPlaceRow')
class LocationPlaceCache extends Table {
  TextColumn get placeKey => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  TextColumn get countryCode => text().nullable()();
  TextColumn get countryName => text().nullable()();
  TextColumn get locality => text().nullable()();
  TextColumn get adminArea => text().nullable()();
  IntColumn get geocodedAt => integer()();

  @override
  Set<Column> get primaryKey => {placeKey};
}
