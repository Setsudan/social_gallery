import 'package:flutter_test/flutter_test.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/domain/usecases/suggest_keep_best.dart';

void main() {
  test('keeps newest item by date', () {
    final useCase = SuggestKeepBest();
    final items = [
      const MediaItem(
        id: 1,
        uri: 'a',
        displayName: 'a',
        folderName: 'f',
        folderPath: 'p',
        dateAdded: 0,
        dateModified: 100,
        dateTaken: 100,
        size: 5000,
        mimeType: 'image/jpeg',
      ),
      const MediaItem(
        id: 2,
        uri: 'b',
        displayName: 'b',
        folderName: 'f',
        folderPath: 'p',
        dateAdded: 0,
        dateModified: 500,
        dateTaken: 500,
        size: 5000,
        mimeType: 'image/jpeg',
      ),
    ];

    final keeper = useCase(items);
    expect(keeper.id, 2);
    expect(useCase.idsToRemove(items), {1});
  });
}
