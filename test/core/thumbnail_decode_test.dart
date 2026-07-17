import 'package:flutter_test/flutter_test.dart';
import 'package:social_gallery/core/media/thumbnail_decode.dart';

void main() {
  group('snapThumbnailEdge', () {
    test('snaps up to discrete buckets', () {
      expect(snapThumbnailEdge(1), 96);
      expect(snapThumbnailEdge(96), 96);
      expect(snapThumbnailEdge(97), 128);
      expect(snapThumbnailEdge(250), 256);
      expect(snapThumbnailEdge(321), 384);
      expect(snapThumbnailEdge(2000), 1080);
    });
  });

  group('thumbnailDecodeEdge', () {
    test('respects max edge and snaps', () {
      expect(
        thumbnailDecodeEdge(
          logicalWidth: 120,
          devicePixelRatio: 3,
          maxEdge: 320,
        ),
        320,
      );
      expect(
        thumbnailDecodeEdge(
          logicalWidth: 40,
          devicePixelRatio: 2,
          maxEdge: 320,
        ),
        96,
      );
    });
  });
}
