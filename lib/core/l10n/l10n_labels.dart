import 'package:flutter/material.dart';
import 'package:social_gallery/core/l10n/app_locale_preference.dart';
import 'package:social_gallery/core/theme/accent_presets.dart';
import 'package:social_gallery/core/theme/app_theme_variant.dart';
import 'package:social_gallery/domain/models/desktop_gallery_grid_size.dart';
import 'package:social_gallery/l10n/app_localizations.dart';

String appThemeVariantLabel(AppLocalizations l10n, AppThemeVariant variant) {
  return switch (variant) {
    AppThemeVariant.system => l10n.themeSystemDefault,
    AppThemeVariant.light => l10n.themeLight,
    AppThemeVariant.solar => l10n.themeSolar,
    AppThemeVariant.dark => l10n.themeDark,
    AppThemeVariant.darkOled => l10n.themeDarkOled,
  };
}

String accentPresetLabel(AppLocalizations l10n, Color color) {
  final id = AccentPresets.idFor(color);
  return switch (id) {
    AccentPresetId.blue => l10n.accentBlue,
    AccentPresetId.purple => l10n.accentPurple,
    AccentPresetId.green => l10n.accentGreen,
    AccentPresetId.orange => l10n.accentOrange,
    AccentPresetId.red => l10n.accentRed,
    AccentPresetId.pink => l10n.accentPink,
    AccentPresetId.teal => l10n.accentTeal,
    null => l10n.accentBlue,
  };
}

String desktopGalleryGridSizeLabel(
  AppLocalizations l10n,
  DesktopGalleryGridSize size,
) {
  return switch (size) {
    DesktopGalleryGridSize.compact => l10n.gridSizeCompact,
    DesktopGalleryGridSize.standard => l10n.gridSizeStandard,
    DesktopGalleryGridSize.large => l10n.gridSizeLarge,
  };
}

String desktopGalleryGridSizeSubtitle(
  AppLocalizations l10n,
  DesktopGalleryGridSize size,
) {
  return switch (size) {
    DesktopGalleryGridSize.compact => l10n.gridSizeCompactSubtitle,
    DesktopGalleryGridSize.standard => l10n.gridSizeStandardSubtitle,
    DesktopGalleryGridSize.large => l10n.gridSizeLargeSubtitle,
  };
}

String fontSizeLabel(AppLocalizations l10n, double factor) {
  if (factor < 0.9) return l10n.fontSizeSmall;
  if (factor < 1.1) return l10n.fontSizeNormal;
  if (factor < 1.3) return l10n.fontSizeLarge;
  return l10n.fontSizeExtraLarge;
}

String animationSpeedLabel(AppLocalizations l10n, double speed) {
  if (speed <= 0.01) return l10n.animationSpeedInstant;
  if (speed < 0.75) return l10n.animationSpeedFast;
  if (speed < 1.5) return l10n.animationSpeedNormal;
  return l10n.animationSpeedSlow;
}

String appLocalePreferenceLabel(
  AppLocalizations l10n,
  AppLocalePreference preference,
) {
  return switch (preference) {
    AppLocalePreference.system => l10n.settingsLanguageSystem,
    AppLocalePreference.en => l10n.settingsLanguageEnglish,
    AppLocalePreference.fr => l10n.settingsLanguageFrench,
  };
}
