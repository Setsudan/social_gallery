import 'package:flutter_test/flutter_test.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/shared/navigation/media_viewer_session.dart';

MediaItem _item(int id) => MediaItem(
      id: id,
      uri: 'uri_$id',
      displayName: 'item_$id',
      folderName: 'folder',
      folderPath: '/folder',
      dateAdded: id,
      dateModified: id,
      size: 1,
      mimeType: 'image/jpeg',
    );

void main() {
  test('boundMediaViewerWindow keeps small lists intact', () {
    final items = List.generate(10, _item);
    final window = boundMediaViewerWindow(items, 4, maxItems: 120);
    expect(window.items.length, 10);
    expect(window.index, 4);
  });

  test('boundMediaViewerWindow centers a capped window on the tapped index', () {
    final items = List.generate(200, _item);
    final window = boundMediaViewerWindow(items, 100, maxItems: 120);
    expect(window.items.length, 120);
    expect(window.items.first.id, 40);
    expect(window.items.last.id, 159);
    expect(window.index, 60);
    expect(window.items[window.index].id, 100);
  });

  test('boundMediaViewerWindow clamps near list edges', () {
    final items = List.generate(200, _item);
    final start = boundMediaViewerWindow(items, 2, maxItems: 120);
    expect(start.items.first.id, 0);
    expect(start.index, 2);

    final end = boundMediaViewerWindow(items, 198, maxItems: 120);
    expect(end.items.last.id, 199);
    expect(end.items[end.index].id, 198);
  });
}
