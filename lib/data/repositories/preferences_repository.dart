import 'package:shared_preferences/shared_preferences.dart';

class PreferencesRepository {
  PreferencesRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _initialSetupKey = 'initial_setup_complete';
  static const _activeProfileFolderKey = 'active_profile_folder';

  bool get hasCompletedInitialSetup =>
      _prefs.getBool(_initialSetupKey) ?? false;

  Future<void> setInitialSetupComplete() async {
    await _prefs.setBool(_initialSetupKey, true);
  }

  String? get activeProfileFolderPath =>
      _prefs.getString(_activeProfileFolderKey);

  Future<void> setActiveProfileFolderPath(String path) async {
    await _prefs.setString(_activeProfileFolderKey, path);
  }
}
