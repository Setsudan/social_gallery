import 'package:flutter/material.dart';
import 'package:social_gallery/core/theme/app_theme_variant.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';

class AppTheme {
  static ThemeData build({
    required AppThemeVariant variant,
    required Color accent,
  }) {
    return OneUiTheme.build(variant: variant, accent: accent);
  }
}
