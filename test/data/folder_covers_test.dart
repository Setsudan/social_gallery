import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_gallery/data/local/app_database.dart';
import 'package:social_gallery/data/mappers/entity_mappers.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedAlbum() async {
    await db.upsertFolders([
      FoldersCompanion.insert(
        path: '/album',
        name: 'Album',
        mediaCount: const Value(2),
        lastModified: const Value(0),
        followStatus: const Value('HOME_FEED'),
      ),
    ]);

    await db.replaceAllMedia([
      MediaItemsCompanion.insert(
        id: const Value(1),
        uri: 'older-asset',
        displayName: 'older.jpg',
        folderName: 'Album',
        folderPath: '/album',
        dateAdded: 100,
        dateModified: 100,
        dateTaken: const Value(100),
        size: 1000,
        mimeType: 'image/jpeg',
      ),
      MediaItemsCompanion.insert(
        id: const Value(2),
        uri: 'latest-asset',
        displayName: 'latest.jpg',
        folderName: 'Album',
        folderPath: '/album',
        dateAdded: 200,
        dateModified: 200,
        dateTaken: const Value(300),
        size: 1000,
        mimeType: 'image/jpeg',
      ),
    ]);
  }

  test('repairFolderCovers uses latest media uri as auto cover', () async {
    await seedAlbum();
    await db.repairFolderCovers();

    final folder = await db.getFolder('/album');
    expect(folder?.coverImageUri, 'latest-asset');
  });

  test('displayCoverUri prefers custom cover over auto cover', () async {
    await seedAlbum();
    await db.setFolderCustomCover('/album', 'older-asset');
    await db.repairFolderCovers();

    final folder = folderFromRow((await db.getFolder('/album'))!);
    expect(folder.displayCoverUri, 'older-asset');
  });

  test('repairFolderCovers clears custom cover missing from album media', () async {
    await seedAlbum();
    await db.setFolderCustomCover('/album', 'deleted-asset');
    await db.repairFolderCovers();

    final folder = folderFromRow((await db.getFolder('/album'))!);
    expect(folder.customCoverUri, isNull);
    expect(folder.displayCoverUri, 'latest-asset');
  });

  if (!Platform.isWindows) {
    test('repairFolderCovers clears stale filesystem custom covers', () async {
      await seedAlbum();
      await (db.update(db.folders)..where((f) => f.path.equals('/album'))).write(
        const FoldersCompanion(
          customCoverUri: Value('/storage/emulated/0/Pictures/stale.jpg'),
        ),
      );

      await db.repairFolderCovers();

      final folder = folderFromRow((await db.getFolder('/album'))!);
      expect(folder.customCoverUri, isNull);
      expect(folder.displayCoverUri, 'latest-asset');
    });
  }

  test('upsertFolders preserves existing cover uri during sync', () async {
    await seedAlbum();
    await db.repairFolderCovers();

    await db.upsertFolders([
      FoldersCompanion.insert(
        path: '/album',
        name: 'Album Renamed',
        mediaCount: const Value(2),
        lastModified: const Value(1),
        followStatus: const Value('HOME_FEED'),
      ),
    ]);

    final folder = await db.getFolder('/album');
    expect(folder?.coverImageUri, 'latest-asset');
    expect(folder?.name, 'Album Renamed');
  });
}
