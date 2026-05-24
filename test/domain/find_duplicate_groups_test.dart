import 'package:flutter_test/flutter_test.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/domain/usecases/find_duplicate_groups.dart';

void main() {
  test('groups items with same size and dimensions', () {
    final useCase = FindDuplicateGroups();
    final items = [
      const MediaItem(
        id: 1,
        uri: 'a',
        displayName: 'a',
        folderName: 'f',
        folderPath: 'p',
        dateAdded: 0,
        dateModified: 100,
        size: 5000,
        mimeType: 'image/jpeg',
        width: 100,
        height: 100,
      ),
      const MediaItem(
        id: 2,
        uri: 'b',
        displayName: 'b',
        folderName: 'f',
        folderPath: 'p',
        dateAdded: 0,
        dateModified: 200,
        size: 5000,
        mimeType: 'image/jpeg',
        width: 100,
        height: 100,
      ),
      const MediaItem(
        id: 3,
        uri: 'c',
        displayName: 'c',
        folderName: 'f',
        folderPath: 'p',
        dateAdded: 0,
        dateModified: 300,
        size: 9000,
        mimeType: 'image/jpeg',
        width: 200,
        height: 200,
      ),
    ];

    final groups = useCase(items);
    expect(groups.length, 1);
    expect(groups.first.count, 2);
  });
}
