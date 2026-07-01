import 'package:flutter/material.dart';

enum AppThemeVariant { system, light, solar, dark, darkOled }

AppThemeVariant resolveAppThemeVariant(
  AppThemeVariant stored,
  Brightness platform,
) {
  if (stored != AppThemeVariant.system) return stored;
  return platform == Brightness.dark
      ? AppThemeVariant.dark
      : AppThemeVariant.light;
}

AppThemeVariant appThemeVariantFromString(String value) {
  return switch (value) {
    'light' => AppThemeVariant.light,
    'solar' => AppThemeVariant.solar,
    'dark' => AppThemeVariant.dark,
    'dark_oled' => AppThemeVariant.darkOled,
    _ => AppThemeVariant.system,
  };
}

String appThemeVariantToString(AppThemeVariant variant) {
  return switch (variant) {
    AppThemeVariant.system => 'system',
    AppThemeVariant.light => 'light',
    AppThemeVariant.solar => 'solar',
    AppThemeVariant.dark => 'dark',
    AppThemeVariant.darkOled => 'dark_oled',
  };
}
