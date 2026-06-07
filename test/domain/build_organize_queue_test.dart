import 'package:flutter_test/flutter_test.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/domain/models/organize_models.dart';
import 'package:social_gallery/domain/usecases/build_organize_queue.dart';

MediaItem _item({
  required int id,
  String folderPath = 'folder-a',
  bool isVideo = false,
  int sortDate = 1000,
}) {
  return MediaItem(
    id: id,
    uri: 'uri_$id',
    displayName: 'img_$id.jpg',
    folderName: 'Folder',
    folderPath: folderPath,
    dateAdded: sortDate,
    dateModified: sortDate,
    dateTaken: sortDate,
    size: 1000,
    mimeType: isVideo ? 'video/mp4' : 'image/jpeg',
    width: 100,
    height: 100,
  );
}

void main() {
  final buildQueue = BuildOrganizeQueue();

  test('excludes processed and pending trash ids', () {
    final pool = [_item(id: 1), _item(id: 2), _item(id: 3)];
    final queue = buildQueue(
      pool: pool,
      processedIds: {1},
      pendingTrashIds: {2},
      filter: const OrganizeFilter(),
      order: OrganizeQueueOrder.chronological,
      batchSize: 16,
    );
    expect(queue.map((e) => e.id), [3]);
  });

  test('filters by folder and media type', () {
    final pool = [
      _item(id: 1, folderPath: 'a'),
      _item(id: 2, folderPath: 'b'),
      _item(id: 3, isVideo: true),
    ];
    final queue = buildQueue(
      pool: pool,
      processedIds: {},
      pendingTrashIds: {},
      filter: const OrganizeFilter(
        folderPath: 'a',
        mediaType: OrganizeMediaType.image,
      ),
      order: OrganizeQueueOrder.chronological,
      batchSize: 16,
    );
    expect(queue.map((e) => e.id), [1]);
  });

  test('filters by month', () {
    final jan = DateTime(2024, 1, 15).millisecondsSinceEpoch;
    final feb = DateTime(2024, 2, 10).millisecondsSinceEpoch;
    final pool = [_item(id: 1, sortDate: jan), _item(id: 2, sortDate: feb)];
    final queue = buildQueue(
      pool: pool,
      processedIds: {},
      pendingTrashIds: {},
      filter: const OrganizeFilter(month: '2024-02'),
      order: OrganizeQueueOrder.chronological,
      batchSize: 16,
    );
    expect(queue.map((e) => e.id), [2]);
  });

  test('respects batch size', () {
    final pool = List.generate(20, (i) => _item(id: i, sortDate: i));
    final queue = buildQueue(
      pool: pool,
      processedIds: {},
      pendingTrashIds: {},
      filter: const OrganizeFilter(),
      order: OrganizeQueueOrder.chronological,
      batchSize: 5,
    );
    expect(queue.length, 5);
  });
}
