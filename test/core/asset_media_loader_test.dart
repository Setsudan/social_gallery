import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:social_gallery/core/media/asset_media_loader.dart';
import 'package:social_gallery/core/media/asset_media_kind.dart';

void main() {
  group('AssetMediaLoader.classify', () {
    test('native image and video map directly', () {
      expect(
        AssetMediaLoader.classify(_entity(type: AssetType.image)),
        AssetMediaKind.image,
      );
      expect(
        AssetMediaLoader.classify(_entity(type: AssetType.video)),
        AssetMediaKind.video,
      );
      expect(
        AssetMediaLoader.classify(_entity(type: AssetType.audio)),
        AssetMediaKind.audio,
      );
    });

    test('other with image mime is image', () {
      expect(
        AssetMediaLoader.classify(
          _entity(type: AssetType.other, mimeType: 'image/heif'),
        ),
        AssetMediaKind.image,
      );
    });

    test('other with video extension is video', () {
      expect(
        AssetMediaLoader.classify(
          _entity(type: AssetType.other, title: 'clip.MOV'),
        ),
        AssetMediaKind.video,
      );
    });

    test('other with unknown name is unsupported', () {
      expect(
        AssetMediaLoader.classify(
          _entity(type: AssetType.other, title: 'readme'),
        ),
        AssetMediaKind.unsupported,
      );
    });
  });

  group('AssetMediaLoader.canUseAssetImageProvider', () {
    test('only image and video native types', () {
      expect(
        AssetMediaLoader.canUseAssetImageProvider(
          _entity(type: AssetType.image),
        ),
        isTrue,
      );
      expect(
        AssetMediaLoader.canUseAssetImageProvider(
          _entity(type: AssetType.other),
        ),
        isFalse,
      );
    });
  });
}

AssetEntity _entity({
  required AssetType type,
  String? title,
  String? mimeType,
}) {
  return AssetEntity(
    id: 'test',
    typeInt: type.index,
    width: 100,
    height: 100,
    title: title,
    mimeType: mimeType,
  );
}
