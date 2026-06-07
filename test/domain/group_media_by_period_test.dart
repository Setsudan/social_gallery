import 'package:flutter_test/flutter_test.dart';
import 'package:social_gallery/domain/models/gallery_grouping_period.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/domain/usecases/group_media_by_period.dart';

MediaItem _item({
  required int id,
  required int sortDate,
}) {
  return MediaItem(
    id: id,
    uri: 'asset_$id',
    displayName: 'photo_$id.jpg',
    folderName: 'Camera',
    folderPath: '/camera',
    dateAdded: sortDate,
    dateModified: sortDate,
    dateTaken: sortDate,
    size: 1000,
    mimeType: 'image/jpeg',
  );
}

void main() {
  final groupMedia = GroupMediaByPeriod();

  test('groups media by day', () {
    final dayOne = DateTime(2024, 3, 1).millisecondsSinceEpoch;
    final dayTwo = DateTime(2024, 3, 2).millisecondsSinceEpoch;

    final groups = groupMedia(
      items: [
        _item(id: 1, sortDate: dayOne),
        _item(id: 2, sortDate: dayTwo),
        _item(id: 3, sortDate: dayOne + 1000),
      ],
      period: GalleryGroupingPeriod.day,
    );

    expect(groups.length, 2);
    final marchFirst = groups.firstWhere((group) => group.key == '2024-03-01');
    final marchSecond = groups.firstWhere((group) => group.key == '2024-03-02');
    expect(marchFirst.items.length, 2);
    expect(marchSecond.items.length, 1);
  });

  test('groups media by month', () {
    final march = DateTime(2024, 3, 15).millisecondsSinceEpoch;
    final april = DateTime(2024, 4, 2).millisecondsSinceEpoch;

    final groups = groupMedia(
      items: [
        _item(id: 1, sortDate: march),
        _item(id: 2, sortDate: april),
        _item(id: 3, sortDate: DateTime(2024, 3, 20).millisecondsSinceEpoch),
      ],
      period: GalleryGroupingPeriod.month,
    );

    expect(groups.length, 2);
    expect(groups.first.key, '2024-04');
    expect(groups.last.key, '2024-03');
  });

  test('groups media by year', () {
    final groups = groupMedia(
      items: [
        _item(id: 1, sortDate: DateTime(2023, 12, 31).millisecondsSinceEpoch),
        _item(id: 2, sortDate: DateTime(2024, 1, 1).millisecondsSinceEpoch),
      ],
      period: GalleryGroupingPeriod.year,
    );

    expect(groups.length, 2);
    expect(groups.first.key, '2024');
    expect(groups.last.key, '2023');
  });
}
