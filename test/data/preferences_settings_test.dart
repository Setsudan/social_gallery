import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_gallery/data/repositories/preferences_repository.dart';
import 'package:social_gallery/domain/models/desktop_gallery_grid_size.dart';
import 'package:social_gallery/domain/models/organize_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('organize gesture mapping persists', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = PreferencesRepository(prefs);

    expect(repo.organizeGestureMapping, OrganizeGestureMapping.defaults);

    final custom = OrganizeGestureMapping.defaults.remap(
      OrganizeSwipeDirection.left,
      OrganizeSwipeAction.keep,
    );
    await repo.setOrganizeGestureMapping(custom);
    expect(repo.organizeGestureMapping, custom);

    final again = PreferencesRepository(prefs);
    expect(again.organizeGestureMapping, custom);
  });

  test('gallery grid density persists', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = PreferencesRepository(prefs);

    expect(repo.desktopGalleryGridSize, DesktopGalleryGridSize.standard);
    await repo.setDesktopGalleryGridSize(DesktopGalleryGridSize.compact);
    expect(repo.desktopGalleryGridSize, DesktopGalleryGridSize.compact);
  });
}
