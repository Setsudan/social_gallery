import 'package:flutter/material.dart';
import 'package:social_gallery/core/l10n/app_locale_preference.dart';

class LocalePreferenceFlag extends StatelessWidget {
  const LocalePreferenceFlag({
    super.key,
    required this.preference,
    this.size = 28,
  });

  final AppLocalePreference preference;
  final double size;

  @override
  Widget build(BuildContext context) {
    final countryCode = preference.flagCountryCode;
    if (countryCode == null) {
      return Icon(Icons.public_rounded, size: size);
    }
    return Text(
      flagEmojiForCountryCode(countryCode),
      style: TextStyle(fontSize: size),
    );
  }
}
