import 'package:drift/drift.dart';

class TravelModes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get startDate => integer()();
  IntColumn get endDate => integer()();
  IntColumn get startTime => integer().nullable()();
  IntColumn get endTime => integer().nullable()();
  TextColumn get folderPath => text()();
  IntColumn get createdAt => integer()();
  IntColumn get notificationEndingSoonHours =>
      integer().withDefault(const Constant(24))();

  @override
  Set<Column> get primaryKey => {id};
}
