import 'package:flutter_test/flutter_test.dart';
import 'package:social_gallery/domain/models/desktop_gallery_grid_size.dart';

void main() {
  group('DesktopGalleryGridSize', () {
    test('fromStorage defaults to comfortable/standard', () {
      expect(DesktopGalleryGridSize.fromStorage(null), DesktopGalleryGridSize.standard);
      expect(DesktopGalleryGridSize.fromStorage('nope'), DesktopGalleryGridSize.standard);
      expect(DesktopGalleryGridSize.fromStorage('compact'), DesktopGalleryGridSize.compact);
      expect(DesktopGalleryGridSize.fromStorage('large'), DesktopGalleryGridSize.large);
    });

    test('adjustColumnCount applies density deltas with clamp', () {
      expect(DesktopGalleryGridSize.compact.adjustColumnCount(3), 6);
      expect(DesktopGalleryGridSize.standard.adjustColumnCount(3), 3);
      expect(DesktopGalleryGridSize.large.adjustColumnCount(3), 2);
      expect(DesktopGalleryGridSize.large.adjustColumnCount(2), 2);
      expect(DesktopGalleryGridSize.compact.adjustColumnCount(18), 20);
    });
  });
}
