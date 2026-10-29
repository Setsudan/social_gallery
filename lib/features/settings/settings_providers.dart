import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers/data_providers.dart';
import 'package:social_gallery/features/settings/settings_controller.dart';

export 'settings_controller.dart';

/// Global settings: theme, gallery view mode, trash retention, cache limits.
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((
  ref,
) {
  final preferencesRepository = ref.watch(preferencesRepositoryProvider);
  return SettingsNotifier(preferencesRepository);
});
