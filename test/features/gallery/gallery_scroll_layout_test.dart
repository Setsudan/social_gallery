import 'package:flutter_test/flutter_test.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/domain/usecases/group_media_by_period.dart';
import 'package:social_gallery/features/gallery/gallery_scroll_layout.dart';

MediaItem _item(int id) {
  return MediaItem(
    id: id,
    uri: 'asset-$id',
    displayName: 'p$id',
    folderName: 'f',
    folderPath: '/f',
    dateAdded: id,
    dateModified: id,
    size: 1,
    mimeType: 'image/jpeg',
  );
}

void main() {
  test('flattens groups into fixed-extent rows', () {
    final layout = GalleryTimelineLayout.build(
      groups: [
        MediaPeriodGroup(
          key: 'day-a',
          label: 'Today',
          items: [_item(1), _item(2), _item(3)],
        ),
        MediaPeriodGroup(key: 'day-b', label: 'Yesterday', items: [_item(4)]),
      ],
      columns: 2,
      viewportWidth: 102,
      headerExtent: 40,
      showLoader: true,
    );

    expect(layout.rows.map((row) => row.kind).toList(), [
      GalleryTimelineRowKind.header,
      GalleryTimelineRowKind.tiles,
      GalleryTimelineRowKind.tiles,
      GalleryTimelineRowKind.header,
      GalleryTimelineRowKind.tiles,
      GalleryTimelineRowKind.loader,
    ]);
    expect(layout.cellExtent, 48);
    expect(layout.extentAt(1), 48 + GalleryTimelineLayout.tileGap);
    expect(layout.extentAt(2), 48 + GalleryTimelineLayout.groupBottomGap);
    expect(layout.rows[1].items.map((item) => item.id), [1, 2]);
    expect(layout.rows[2].flatIndex, 2);
    expect(layout.rows[4].flatIndex, 3);
    expect(layout.rows[5].flatIndex, 4);
    expect(layout.indexForKey('h:day-b'), 3);
    expect(layout.indexForKey('t:3'), 2);

    expect(layout.flatIndexAt(0), 0);
    expect(layout.flatIndexAt(40), 0);
    expect(layout.flatIndexAt(40 + 50), 2);
    final beforeSecondHeader = layout.offsets[3] - 0.1;
    expect(layout.flatIndexAt(beforeSecondHeader), 2);
    expect(layout.flatIndexAt(layout.offsets[3]), 3);
    expect(layout.flatIndexAt(layout.offsets.last + 20), 3);
  });

  test('cell extent stays within the viewport', () {
    const width = 390.0;
    const columns = 6;
    final cell = GalleryTimelineLayout.cellExtentFor(
      viewportWidth: width,
      columns: columns,
    );
    final used =
        GalleryTimelineLayout.horizontalInset * 2 +
        cell * columns +
        GalleryTimelineLayout.tileGap * (columns - 1);
    expect(used, lessThanOrEqualTo(width));
    expect(cell, greaterThan(1));
  });
}
