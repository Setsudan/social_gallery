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

  test('searchExploreMediaFiltered matches label and color', () async {
    await db.upsertFolders([
      FoldersCompanion.insert(
        path: '/photos',
        name: 'Photos',
        mediaCount: const Value(2),
        lastModified: const Value(0),
        followStatus: const Value('HOME_FEED'),
        isBiometricLocked: const Value(false),
      ),
    ]);
    await db.replaceAllMedia([
      MediaItemsCompanion.insert(
        id: const Value(1),
        uri: 'file:///a.jpg',
        displayName: 'a.jpg',
        folderName: 'Photos',
        folderPath: '/photos',
        dateAdded: 1,
        dateModified: 1,
        size: 100,
        mimeType: 'image/jpeg',
      ),
      MediaItemsCompanion.insert(
        id: const Value(2),
        uri: 'file:///b.jpg',
        displayName: 'b.jpg',
        folderName: 'Photos',
        folderPath: '/photos',
        dateAdded: 2,
        dateModified: 2,
        size: 100,
        mimeType: 'image/jpeg',
      ),
    ]);
    await db.upsertAnalysisRow(
      const MediaAnalysisCacheCompanion(
        mediaId: Value(1),
        labelsJson: Value('["cat","pet"]'),
        dominantColor: Value('orange'),
        scannedAt: Value(1),
      ),
    );
    await db.upsertAnalysisRow(
      const MediaAnalysisCacheCompanion(
        mediaId: Value(2),
        labelsJson: Value('["car"]'),
        dominantColor: Value('blue'),
        scannedAt: Value(2),
      ),
    );

    final catResults = await db.searchExploreMediaFiltered(
      label: 'cat',
      limit: 10,
      offset: 0,
    );
    expect(catResults.map((row) => row.id), [1]);

    final blueResults = await db.searchExploreMediaFiltered(
      color: 'blue',
      limit: 10,
      offset: 0,
    );
    expect(blueResults.map((row) => row.id), [2]);
  });
}
