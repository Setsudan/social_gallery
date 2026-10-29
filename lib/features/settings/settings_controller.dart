import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/core/l10n/app_locale_preference.dart';
import 'package:social_gallery/core/theme/accent_presets.dart';
import 'package:social_gallery/core/theme/app_theme_variant.dart';
import 'package:social_gallery/data/repositories/preferences_repository.dart';
import 'package:social_gallery/domain/models/desktop_gallery_grid_size.dart';
import 'package:social_gallery/domain/models/organize_models.dart';

/// User preferences mirrored from [PreferencesRepository] for UI binding.
class AppSettings {
  final AppThemeVariant appTheme;
  final Color accentColor;
  final double fontSizeFactor;
  final double animationSpeed;
  final int trashRetentionDays;
  final int cacheSizeLimitMb;
  final bool autoClearCacheOnClose;
  final bool galleryViewMode;
  final DesktopGalleryGridSize desktopGalleryGridSize;
  final OrganizeGestureMapping organizeGestureMapping;
  final AppLocalePreference localePreference;

  const AppSettings({
    required this.appTheme,
    required this.accentColor,
    required this.fontSizeFactor,
    required this.animationSpeed,
    required this.trashRetentionDays,
    required this.cacheSizeLimitMb,
    required this.autoClearCacheOnClose,
    required this.galleryViewMode,
    required this.desktopGalleryGridSize,
    required this.organizeGestureMapping,
    required this.localePreference,
  });

  AppSettings copyWith({
    AppThemeVariant? appTheme,
    Color? accentColor,
    double? fontSizeFactor,
    double? animationSpeed,
    int? trashRetentionDays,
    int? cacheSizeLimitMb,
    bool? autoClearCacheOnClose,
    bool? galleryViewMode,
    DesktopGalleryGridSize? desktopGalleryGridSize,
    OrganizeGestureMapping? organizeGestureMapping,
    AppLocalePreference? localePreference,
  }) {
    return AppSettings(
      appTheme: appTheme ?? this.appTheme,
      accentColor: accentColor ?? this.accentColor,
      fontSizeFactor: fontSizeFactor ?? this.fontSizeFactor,
      animationSpeed: animationSpeed ?? this.animationSpeed,
      trashRetentionDays: trashRetentionDays ?? this.trashRetentionDays,
      cacheSizeLimitMb: cacheSizeLimitMb ?? this.cacheSizeLimitMb,
      autoClearCacheOnClose:
          autoClearCacheOnClose ?? this.autoClearCacheOnClose,
      galleryViewMode: galleryViewMode ?? this.galleryViewMode,
      desktopGalleryGridSize:
          desktopGalleryGridSize ?? this.desktopGalleryGridSize,
      organizeGestureMapping:
          organizeGestureMapping ?? this.organizeGestureMapping,
      localePreference: localePreference ?? this.localePreference,
    );
  }
}

/// Persists [AppSettings] changes to SharedPreferences.
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._preferencesRepository)
    : super(_loadInitial(_preferencesRepository));

  final PreferencesRepository _preferencesRepository;

  static AppSettings _loadInitial(PreferencesRepository preferencesRepository) {
    return AppSettings(
      appTheme: appThemeVariantFromString(preferencesRepository.themeMode),
      accentColor: AccentPresets.resolve(preferencesRepository.accentColorArgb),
      fontSizeFactor: preferencesRepository.fontSizeFactor,
      animationSpeed: preferencesRepository.animationSpeed,
      trashRetentionDays: preferencesRepository.trashRetentionDays,
      cacheSizeLimitMb: preferencesRepository.cacheSizeLimitMb,
      autoClearCacheOnClose: preferencesRepository.autoClearCacheOnClose,
      galleryViewMode: preferencesRepository.galleryViewMode,
      desktopGalleryGridSize: preferencesRepository.desktopGalleryGridSize,
      organizeGestureMapping: preferencesRepository.organizeGestureMapping,
      localePreference: preferencesRepository.localePreference,
    );
  }

  Future<void> setAppTheme(AppThemeVariant variant) async {
    state = state.copyWith(appTheme: variant);
    await _preferencesRepository.setThemeMode(appThemeVariantToString(variant));
  }

  Future<void> setAccentColor(Color color) async {
    if (!AccentPresets.isPreset(color)) return;
    state = state.copyWith(accentColor: color);
    await _preferencesRepository.setAccentColorArgb(color.toARGB32());
  }

  Future<void> setFontSizeFactor(double factor) async {
    state = state.copyWith(fontSizeFactor: factor);
    await _preferencesRepository.setFontSizeFactor(factor);
  }

  Future<void> setAnimationSpeed(double speed) async {
    state = state.copyWith(animationSpeed: speed);
    await _preferencesRepository.setAnimationSpeed(speed);
  }

  Future<void> setTrashRetentionDays(int days) async {
    state = state.copyWith(trashRetentionDays: days);
    await _preferencesRepository.setTrashRetentionDays(days);
  }

  Future<void> setCacheSizeLimitMb(int megabytes) async {
    state = state.copyWith(cacheSizeLimitMb: megabytes);
    await _preferencesRepository.setCacheSizeLimitMb(megabytes);
  }

  Future<void> setAutoClearCacheOnClose(bool enabled) async {
    state = state.copyWith(autoClearCacheOnClose: enabled);
    await _preferencesRepository.setAutoClearCacheOnClose(enabled);
  }

  Future<void> setGalleryViewMode(bool enabled) async {
    state = state.copyWith(galleryViewMode: enabled);
    await _preferencesRepository.setGalleryViewMode(enabled);
  }

  Future<void> setDesktopGalleryGridSize(DesktopGalleryGridSize size) async {
    state = state.copyWith(desktopGalleryGridSize: size);
    await _preferencesRepository.setDesktopGalleryGridSize(size);
  }

  Future<void> setOrganizeGestureMapping(OrganizeGestureMapping mapping) async {
    final normalizedMapping = OrganizeGestureMapping.ensureBijective(mapping);
    state = state.copyWith(organizeGestureMapping: normalizedMapping);
    await _preferencesRepository.setOrganizeGestureMapping(normalizedMapping);
  }

  Future<void> setLocalePreference(AppLocalePreference preference) async {
    state = state.copyWith(localePreference: preference);
    await _preferencesRepository.setLocalePreference(preference);
  }
}
