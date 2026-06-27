import 'package:flutter_test/flutter_test.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/domain/usecases/find_duplicate_groups.dart';

MediaItem _item(int id, {int size = 5000}) {
  return MediaItem(
    id: id,
    uri: 'uri_$id',
    displayName: 'img_$id.jpg',
    folderName: 'Folder',
    folderPath: 'folder',
    dateAdded: id,
    dateModified: id,
    dateTaken: id,
    size: size,
    mimeType: 'image/jpeg',
    width: 100,
    height: 100,
  );
}

void main() {
  test('groups only visually near-identical images within the same size bucket', () {
    final useCase = FindDuplicateGroups();
    final candidates = [_item(1), _item(2), _item(3), _item(4)];
    final hashesById = {
      1: '0000000000000000000000000000000000000000000000000000000000000000',
      2: '0000000000000000000000000000000000000000000000000000000000000001',
      3: '1111111111111111111111111111111111111111111111111111111111111111',
      4: '1111111111111111111111111111111111111111111111111111111111111110',
    };

    final groups = useCase(candidates: candidates, hashesById: hashesById);
    expect(groups.length, 2);
    expect(groups[0].count, 2);
    expect(groups[0].items.map((item) => item.id).toSet(), {1, 2});
    expect(groups[1].items.map((item) => item.id).toSet(), {3, 4});
  });

  test('does not group images that only share size and dimensions', () {
    final useCase = FindDuplicateGroups();
    final candidates = [_item(1), _item(2)];
    final hashesById = {
      1: '0000000000000000000000000000000000000000000000000000000000000000',
      2: '1111111111111111111111111111111111111111111111111111111111111111',
    };

    final groups = useCase(candidates: candidates, hashesById: hashesById);
    expect(groups, isEmpty);
  });

  test('does not compare items from different size buckets', () {
    final useCase = FindDuplicateGroups();
    final candidates = [_item(1, size: 5000), _item(2, size: 9000)];
    final hashesById = {
      1: '0000000000000000000000000000000000000000000000000000000000000000',
      2: '0000000000000000000000000000000000000000000000000000000000000000',
    };

    final groups = useCase(candidates: candidates, hashesById: hashesById);
    expect(groups, isEmpty);
  });
}
