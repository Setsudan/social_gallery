import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_gallery/data/local/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedFoldersAndMedia() async {
    await db.upsertFolders([
      FoldersCompanion.insert(
        path: '/open',
        name: 'Open',
        mediaCount: const Value(1),
        lastModified: const Value(0),
        followStatus: const Value('HOME_FEED'),
        isBiometricLocked: const Value(false),
      ),
      FoldersCompanion.insert(
        path: '/account',
        name: 'Account',
        mediaCount: const Value(1),
        lastModified: const Value(0),
        followStatus: const Value('ACCOUNT_ONLY'),
        isBiometricLocked: const Value(false),
      ),
      FoldersCompanion.insert(
        path: '/locked',
        name: 'Locked',
        mediaCount: const Value(1),
        lastModified: const Value(0),
        followStatus: const Value('ACCOUNT_ONLY'),
        isBiometricLocked: const Value(true),
      ),
    ]);

    await db.replaceAllMedia([
      MediaItemsCompanion.insert(
        id: const Value(1),
        uri: 'uri-open',
        displayName: 'open.jpg',
        folderName: 'Open',
        folderPath: '/open',
        dateAdded: 100,
        dateModified: 100,
        size: 1000,
        mimeType: 'image/jpeg',
      ),
      MediaItemsCompanion.insert(
        id: const Value(2),
        uri: 'uri-account',
        displayName: 'account.jpg',
        folderName: 'Account',
        folderPath: '/account',
        dateAdded: 200,
        dateModified: 200,
        size: 1000,
        mimeType: 'image/jpeg',
      ),
      MediaItemsCompanion.insert(
        id: const Value(3),
        uri: 'uri-locked',
        displayName: 'locked.jpg',
        folderName: 'Locked',
        folderPath: '/locked',
        dateAdded: 300,
        dateModified: 300,
        size: 1000,
        mimeType: 'image/jpeg',
      ),
    ]);
  }

  test('home feed only includes HOME_FEED folders', () async {
    await seedFoldersAndMedia();
    final rows = await db.getHomeFeedMediaPage(limit: 10, offset: 0);
    expect(rows.map((r) => r.folderPath), ['/open']);
  });

  test('explore and favorites exclude account-only folder media', () async {
    await seedFoldersAndMedia();

    final explore = await db.getExploreMediaPage(limit: 10, offset: 0);
    expect(explore.map((r) => r.folderPath), ['/open']);

    await db.setFavorite(1, true);
    await db.setFavorite(2, true);
    await db.setFavorite(3, true);
    final favorites = await db.watchFavoritesMedia().first;
    expect(favorites.map((r) => r.folderPath), ['/open']);
  });

  test('search folders returns all non-hidden folders by name', () async {
    await seedFoldersAndMedia();
    expect((await db.searchFolders('acc')).map((f) => f.path), ['/account']);
    expect((await db.searchFolders('lock')).map((f) => f.path), ['/locked']);
    expect((await db.searchFolders('open')).map((f) => f.path), ['/open']);
  });

  test('stories folders exclude account-only', () async {
    await seedFoldersAndMedia();
    await (db.update(db.folders)..where((f) => f.path.equals('/account')))
        .write(const FoldersCompanion(showInStories: Value(true)));
    final stories = await db.getStoriesEnabledFolders();
    expect(stories.map((f) => f.path), ['/open']);
  });

  test('duplicate detection ignores account-only folder media', () async {
    await seedFoldersAndMedia();
    await db.replaceAllMedia([
      MediaItemsCompanion.insert(
        id: const Value(1),
        uri: 'a1',
        displayName: 'a1.jpg',
        folderName: 'Open',
        folderPath: '/open',
        dateAdded: 1,
        dateModified: 1,
        size: 500,
        mimeType: 'image/jpeg',
        width: const Value(10),
        height: const Value(10),
      ),
      MediaItemsCompanion.insert(
        id: const Value(2),
        uri: 'a2',
        displayName: 'a2.jpg',
        folderName: 'Open',
        folderPath: '/open',
        dateAdded: 2,
        dateModified: 2,
        size: 500,
        mimeType: 'image/jpeg',
        width: const Value(10),
        height: const Value(10),
      ),
      MediaItemsCompanion.insert(
        id: const Value(3),
        uri: 'l1',
        displayName: 'l1.jpg',
        folderName: 'Locked',
        folderPath: '/locked',
        dateAdded: 3,
        dateModified: 3,
        size: 500,
        mimeType: 'image/jpeg',
        width: const Value(10),
        height: const Value(10),
      ),
    ]);

    final dupes = await db.getPotentialDuplicateMedia();
    expect(dupes.map((r) => r.id).toSet(), {1, 2});
  });
}
