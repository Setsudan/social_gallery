import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_gallery/features/settings/settings_controller.dart';
import 'package:social_gallery/core/theme/accent_presets.dart';
import 'package:social_gallery/core/theme/app_theme_variant.dart';
import 'package:social_gallery/core/l10n/app_locale_preference.dart';
import 'package:social_gallery/data/repositories/preferences_repository.dart';
import 'package:social_gallery/domain/models/desktop_gallery_grid_size.dart';
import 'package:social_gallery/domain/models/organize_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PreferencesRepository preferencesRepository;
  late SettingsNotifier settingsNotifier;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferencesRepository = PreferencesRepository(
      await SharedPreferences.getInstance(),
    );
    settingsNotifier = SettingsNotifier(preferencesRepository);
  });

  tearDown(() => settingsNotifier.dispose());

  test('loads persisted settings when constructed', () async {
    await preferencesRepository.setGalleryViewMode(true);
    await preferencesRepository.setTrashRetentionDays(14);
    await preferencesRepository.setDesktopGalleryGridSize(
      DesktopGalleryGridSize.compact,
    );
    final reloadedNotifier = SettingsNotifier(preferencesRepository);
    addTearDown(reloadedNotifier.dispose);

    expect(reloadedNotifier.state.galleryViewMode, isTrue);
    expect(reloadedNotifier.state.trashRetentionDays, 14);
    expect(
      reloadedNotifier.state.desktopGalleryGridSize,
      DesktopGalleryGridSize.compact,
    );
  });

  test('updates state immediately and persists preferences', () async {
    final pendingUpdate = settingsNotifier.setGalleryViewMode(true);
    expect(settingsNotifier.state.galleryViewMode, isTrue);
    await pendingUpdate;
    expect(preferencesRepository.galleryViewMode, isTrue);

    await settingsNotifier.setTrashRetentionDays(7);
    await settingsNotifier.setCacheSizeLimitMb(128);
    expect(settingsNotifier.state.trashRetentionDays, 7);
    expect(preferencesRepository.trashRetentionDays, 7);
    expect(settingsNotifier.state.cacheSizeLimitMb, 128);
    expect(preferencesRepository.cacheSizeLimitMb, 128);
  });

  test(
    'persists appearance, locale, cache, and grid changes across reload',
    () async {
      await settingsNotifier.setAppTheme(AppThemeVariant.darkOled);
      await settingsNotifier.setAccentColor(AccentPresets.green.color);
      await settingsNotifier.setFontSizeFactor(1.2);
      await settingsNotifier.setAnimationSpeed(0.5);
      await settingsNotifier.setAutoClearCacheOnClose(true);
      await settingsNotifier.setLocalePreference(AppLocalePreference.fr);
      await settingsNotifier.setDesktopGalleryGridSize(
        DesktopGalleryGridSize.compact,
      );

      final reloadedNotifier = SettingsNotifier(preferencesRepository);
      addTearDown(reloadedNotifier.dispose);
      final reloadedSettings = reloadedNotifier.state;
      expect(reloadedSettings.appTheme, AppThemeVariant.darkOled);
      expect(reloadedSettings.accentColor, AccentPresets.green.color);
      expect(reloadedSettings.fontSizeFactor, 1.2);
      expect(reloadedSettings.animationSpeed, 0.5);
      expect(reloadedSettings.autoClearCacheOnClose, isTrue);
      expect(reloadedSettings.localePreference, AppLocalePreference.fr);
      expect(
        reloadedSettings.desktopGalleryGridSize,
        DesktopGalleryGridSize.compact,
      );
      expect(settingsNotifier.state.accentColor, reloadedSettings.accentColor);
      expect(
        settingsNotifier.state.localePreference,
        reloadedSettings.localePreference,
      );
    },
  );

  test('rejects colors outside the accent presets', () async {
    const unsupportedColor = Color(0xff010203);
    expect(AccentPresets.isPreset(unsupportedColor), isFalse);
    final originalColor = settingsNotifier.state.accentColor;
    final originalStoredColor = preferencesRepository.accentColorArgb;

    await settingsNotifier.setAccentColor(unsupportedColor);

    expect(settingsNotifier.state.accentColor, originalColor);
    expect(preferencesRepository.accentColorArgb, originalStoredColor);
  });

  test('normalizes and persists gesture mapping', () async {
    final mapping = OrganizeGestureMapping.defaults.remap(
      OrganizeSwipeDirection.left,
      OrganizeSwipeAction.keep,
    );
    await settingsNotifier.setOrganizeGestureMapping(mapping);
    final expectedMapping = OrganizeGestureMapping.ensureBijective(mapping);

    expect(settingsNotifier.state.organizeGestureMapping, expectedMapping);
    expect(preferencesRepository.organizeGestureMapping, expectedMapping);
  });
}
