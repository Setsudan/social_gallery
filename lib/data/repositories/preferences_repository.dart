import 'package:shared_preferences/shared_preferences.dart';

class PreferencesRepository {
  PreferencesRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _initialSetupKey = 'initial_setup_complete';
  static const _activeProfileFolderKey = 'active_profile_folder';
  static const _windowsGalleryRootKey = 'windows_gallery_root_path';
  static const _themeModeKey = 'settings_theme_mode';
  static const _fontSizeKey = 'settings_font_size';
  static const _animationSpeedKey = 'settings_animation_speed';
  static const _trashRetentionDaysKey = 'settings_trash_retention_days';
  static const _cacheSizeLimitMbKey = 'settings_cache_size_limit_mb';
  static const _autoClearCacheKey = 'settings_auto_clear_cache_on_close';

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

  String? get windowsGalleryRootPath =>
      _prefs.getString(_windowsGalleryRootKey);

  Future<void> setWindowsGalleryRootPath(String path) async {
    await _prefs.setString(_windowsGalleryRootKey, path);
  }

  String get themeMode => _prefs.getString(_themeModeKey) ?? 'system';
  Future<void> setThemeMode(String theme) async {
    await _prefs.setString(_themeModeKey, theme);
  }

  double get fontSizeFactor => _prefs.getDouble(_fontSizeKey) ?? 1.0;
  Future<void> setFontSizeFactor(double factor) async {
    await _prefs.setDouble(_fontSizeKey, factor);
  }

  double get animationSpeed => _prefs.getDouble(_animationSpeedKey) ?? 1.0;
  Future<void> setAnimationSpeed(double speed) async {
    await _prefs.setDouble(_animationSpeedKey, speed);
  }

  int get trashRetentionDays => _prefs.getInt(_trashRetentionDaysKey) ?? 30;
  Future<void> setTrashRetentionDays(int days) async {
    await _prefs.setInt(_trashRetentionDaysKey, days);
  }

  int get cacheSizeLimitMb => _prefs.getInt(_cacheSizeLimitMbKey) ?? 500;
  Future<void> setCacheSizeLimitMb(int mb) async {
    await _prefs.setInt(_cacheSizeLimitMbKey, mb);
  }

  bool get autoClearCacheOnClose => _prefs.getBool(_autoClearCacheKey) ?? false;
  Future<void> setAutoClearCacheOnClose(bool value) async {
    await _prefs.setBool(_autoClearCacheKey, value);
  }
}
