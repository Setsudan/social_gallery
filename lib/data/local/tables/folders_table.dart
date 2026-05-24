import 'package:drift/drift.dart';

class Folders extends Table {
  TextColumn get path => text()();
  TextColumn get name => text()();
  IntColumn get mediaCount => integer().withDefault(const Constant(0))();
  IntColumn get lastModified => integer().withDefault(const Constant(0))();
  TextColumn get coverImageUri => text().nullable()();
  BoolColumn get isHidden => boolean().withDefault(const Constant(false))();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get customCoverUri => text().nullable()();
  TextColumn get followStatus =>
      text().withDefault(const Constant('HOME_FEED'))();
  BoolColumn get showInStories => boolean().withDefault(const Constant(true))();
  BoolColumn get isBiometricLocked =>
      boolean().withDefault(const Constant(false))();
  TextColumn get biography => text().nullable()();
  IntColumn get storyLastViewedTime =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {path};
}
