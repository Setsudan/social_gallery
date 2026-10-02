import 'package:flutter_test/flutter_test.dart';
import 'package:social_gallery/domain/models/organize_models.dart';

void main() {
  group('OrganizeGestureMapping', () {
    test('defaults match historical swipe behavior', () {
      const mapping = OrganizeGestureMapping.defaults;
      expect(mapping.left, OrganizeSwipeAction.trash);
      expect(mapping.right, OrganizeSwipeAction.favorite);
      expect(mapping.up, OrganizeSwipeAction.keep);
      expect(mapping.down, OrganizeSwipeAction.move);
    });

    test('remap swaps when action already owned', () {
      final remapped = OrganizeGestureMapping.defaults.remap(
        OrganizeSwipeDirection.left,
        OrganizeSwipeAction.favorite,
      );
      expect(remapped.left, OrganizeSwipeAction.favorite);
      expect(remapped.right, OrganizeSwipeAction.trash);
      expect(remapped.up, OrganizeSwipeAction.keep);
      expect(remapped.down, OrganizeSwipeAction.move);
    });

    test('json roundtrip', () {
      final original = OrganizeGestureMapping.defaults.remap(
        OrganizeSwipeDirection.up,
        OrganizeSwipeAction.trash,
      );
      final restored = OrganizeGestureMapping.fromJson(original.toJson());
      expect(restored, original);
    });

    test('fromJson falls back to defaults on null', () {
      expect(OrganizeGestureMapping.fromJson(null), OrganizeGestureMapping.defaults);
    });

    test('actionFor and directionFor stay consistent', () {
      const mapping = OrganizeGestureMapping.defaults;
      for (final direction in OrganizeSwipeDirection.values) {
        final action = mapping.actionFor(direction);
        expect(mapping.directionFor(action), direction);
      }
    });
  });

  group('OrganizeSwipeActionStorage', () {
    test('roundtrips storage values', () {
      for (final action in OrganizeSwipeAction.values) {
        expect(
          OrganizeSwipeActionStorage.fromStorage(action.storageValue),
          action,
        );
      }
      expect(
        OrganizeSwipeActionStorage.fromStorage('unknown'),
        OrganizeSwipeAction.trash,
      );
    });
  });
}
