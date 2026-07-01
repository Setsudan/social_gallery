import 'package:flutter/material.dart';

enum AppLocalePreference {
  system,
  en,
  fr;

  static AppLocalePreference fromStorage(String? value) {
    return switch (value) {
      'en' => AppLocalePreference.en,
      'fr' => AppLocalePreference.fr,
      _ => AppLocalePreference.system,
    };
  }

  String toStorage() {
    return switch (this) {
      AppLocalePreference.system => 'system',
      AppLocalePreference.en => 'en',
      AppLocalePreference.fr => 'fr',
    };
  }

  Locale? toLocale() {
    return switch (this) {
      AppLocalePreference.system => null,
      AppLocalePreference.en => const Locale('en'),
      AppLocalePreference.fr => const Locale('fr'),
    };
  }

  static Locale resolveLocale({
    required AppLocalePreference preference,
    Locale? deviceLocale,
  }) {
    final explicit = preference.toLocale();
    if (explicit != null) return explicit;

    if (deviceLocale != null) {
      for (final supported in supportedLocales) {
        if (supported.languageCode == deviceLocale.languageCode) {
          return supported;
        }
      }
    }
    return const Locale('en');
  }

  static const supportedLocales = [Locale('en'), Locale('fr')];

  /// ISO 3166-1 alpha-2 code for flag display, or null for system default.
  String? get flagCountryCode {
    return switch (this) {
      AppLocalePreference.system => null,
      AppLocalePreference.en => 'US',
      AppLocalePreference.fr => 'FR',
    };
  }
}

String flagEmojiForCountryCode(String countryCode) {
  final normalized = countryCode.toUpperCase();
  if (normalized.length != 2) return '';
  final first = normalized.codeUnitAt(0);
  final second = normalized.codeUnitAt(1);
  if (first < 65 || first > 90 || second < 65 || second > 90) return '';
  return String.fromCharCodes([first + 127397, second + 127397]);
}
