import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_gallery/core/l10n/app_locale_preference.dart';
import 'package:social_gallery/domain/models/desktop_gallery_grid_size.dart';
import 'package:social_gallery/domain/models/recent_search.dart';

/// App settings and onboarding flags stored in SharedPreferences.
class PreferencesRepository {
  PreferencesRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _initialSetupKey = 'initial_setup_complete';
  static const _activeProfileFolderKey = 'active_profile_folder';
  static const _windowsGalleryRootKey = 'windows_gallery_root_path';
  static const _themeModeKey = 'settings_theme_mode';
  static const _accentColorKey = 'settings_accent_color';
  static const _fontSizeKey = 'settings_font_size';
  static const _animationSpeedKey = 'settings_animation_speed';
  static const _trashRetentionDaysKey = 'settings_trash_retention_days';
  static const _cacheSizeLimitMbKey = 'settings_cache_size_limit_mb';
  static const _autoClearCacheKey = 'settings_auto_clear_cache_on_close';
  static const _galleryViewModeKey = 'settings_gallery_view_mode';
  static const _desktopGalleryGridSizeKey = 'settings_desktop_gallery_grid_size';
  static const _localeKey = 'settings_locale';
  static const _lastGallerySyncAtKey = 'last_gallery_sync_at_ms';
  static const _recentSearchesKey = 'explore_recent_searches';
  static const _backupEnabledKey = 'backup_enabled';
  static const _pairedDesktopIdKey = 'paired_desktop_id';
  static const _pairedDesktopNameKey = 'paired_desktop_name';
  static const _backupAuthTokenKey = 'backup_auth_token';
  static const _backupDesktopHostKey = 'backup_desktop_host';
  static const _backupDesktopPortKey = 'backup_desktop_port';
  static const _pairedMobileDeviceNameKey = 'paired_mobile_device_name';
  static const _desktopReceiveBackupsKey = 'desktop_receive_backups';
  static const _desktopBackupRootKey = 'desktop_backup_root';
  static const _lastBackupAtKey = 'last_backup_at_ms';
  static const _backupVerifyCursorKey = 'backup_verify_cursor';
  static const _backupInventoryBackfillDoneKey = 'backup_inventory_backfill_done';
  static const _backupInventoryBackfillRootKey = 'backup_inventory_backfill_root';
  static const _maxRecentSearches = 20;

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

  String? get desktopGalleryRootPath => windowsGalleryRootPath;

  Future<void> setDesktopGalleryRootPath(String path) =>
      setWindowsGalleryRootPath(path);

  String get themeMode => _prefs.getString(_themeModeKey) ?? 'system';
  Future<void> setThemeMode(String theme) async {
    await _prefs.setString(_themeModeKey, theme);
  }

  int? get accentColorArgb => _prefs.getInt(_accentColorKey);
  Future<void> setAccentColorArgb(int argb) async {
    await _prefs.setInt(_accentColorKey, argb);
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

  String get organizeQueueOrder =>
      _prefs.getString('organize_queue_order') ?? 'random';
  Future<void> setOrganizeQueueOrder(String order) async {
    await _prefs.setString('organize_queue_order', order);
  }

  bool get galleryViewMode => _prefs.getBool(_galleryViewModeKey) ?? false;
  Future<void> setGalleryViewMode(bool enabled) async {
    await _prefs.setBool(_galleryViewModeKey, enabled);
  }

  DesktopGalleryGridSize get desktopGalleryGridSize =>
      DesktopGalleryGridSize.fromStorage(
        _prefs.getString(_desktopGalleryGridSizeKey),
      );

  Future<void> setDesktopGalleryGridSize(DesktopGalleryGridSize size) async {
    await _prefs.setString(_desktopGalleryGridSizeKey, size.storageValue);
  }

  AppLocalePreference get localePreference =>
      AppLocalePreference.fromStorage(_prefs.getString(_localeKey));

  Future<void> setLocalePreference(AppLocalePreference value) async {
    await _prefs.setString(_localeKey, value.toStorage());
  }

  DateTime? get lastGallerySyncAt {
    final ms = _prefs.getInt(_lastGallerySyncAtKey);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setLastGallerySyncAt(DateTime time) async {
    await _prefs.setInt(_lastGallerySyncAtKey, time.millisecondsSinceEpoch);
  }

  bool get backupEnabled => _prefs.getBool(_backupEnabledKey) ?? false;
  Future<void> setBackupEnabled(bool value) async {
    await _prefs.setBool(_backupEnabledKey, value);
  }

  String? get pairedDesktopId => _prefs.getString(_pairedDesktopIdKey);
  Future<void> setPairedDesktopId(String id) async {
    await _prefs.setString(_pairedDesktopIdKey, id);
  }

  String? get pairedDesktopName => _prefs.getString(_pairedDesktopNameKey);
  Future<void> setPairedDesktopName(String name) async {
    await _prefs.setString(_pairedDesktopNameKey, name);
  }

  String? get backupAuthToken => _prefs.getString(_backupAuthTokenKey);
  Future<void> setBackupAuthToken(String token) async {
    await _prefs.setString(_backupAuthTokenKey, token);
  }

  String? get backupDesktopHost => _prefs.getString(_backupDesktopHostKey);
  Future<void> setBackupDesktopHost(String host) async {
    await _prefs.setString(_backupDesktopHostKey, host);
  }

  int? get backupDesktopPort => _prefs.getInt(_backupDesktopPortKey);
  Future<void> setBackupDesktopPort(int port) async {
    await _prefs.setInt(_backupDesktopPortKey, port);
  }

  String? get pairedMobileDeviceName =>
      _prefs.getString(_pairedMobileDeviceNameKey);
  Future<void> setPairedMobileDeviceName(String name) async {
    await _prefs.setString(_pairedMobileDeviceNameKey, name);
  }

  bool get desktopReceiveBackups =>
      _prefs.getBool(_desktopReceiveBackupsKey) ?? false;
  Future<void> setDesktopReceiveBackups(bool value) async {
    await _prefs.setBool(_desktopReceiveBackupsKey, value);
  }

  String? get desktopBackupRoot => _prefs.getString(_desktopBackupRootKey);
  Future<void> setDesktopBackupRoot(String path) async {
    await _prefs.setString(_desktopBackupRootKey, path);
  }

  DateTime? get lastBackupAt {
    final ms = _prefs.getInt(_lastBackupAtKey);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setLastBackupAt(DateTime time) async {
    await _prefs.setInt(_lastBackupAtKey, time.millisecondsSinceEpoch);
  }

  int get backupVerifyCursor => _prefs.getInt(_backupVerifyCursorKey) ?? 0;
  Future<void> setBackupVerifyCursor(int value) async {
    await _prefs.setInt(_backupVerifyCursorKey, value);
  }

  bool get backupInventoryBackfillDone =>
      _prefs.getBool(_backupInventoryBackfillDoneKey) ?? false;
  Future<void> setBackupInventoryBackfillDone(bool value) async {
    await _prefs.setBool(_backupInventoryBackfillDoneKey, value);
  }

  String? get backupInventoryBackfillRoot =>
      _prefs.getString(_backupInventoryBackfillRootKey);
  Future<void> setBackupInventoryBackfillRoot(String path) async {
    await _prefs.setString(_backupInventoryBackfillRootKey, path);
  }

  Future<void> clearBackupPairing() async {
    await _prefs.remove(_pairedDesktopIdKey);
    await _prefs.remove(_pairedDesktopNameKey);
    await _prefs.remove(_backupAuthTokenKey);
    await _prefs.remove(_backupDesktopHostKey);
    await _prefs.remove(_backupDesktopPortKey);
    await _prefs.remove(_pairedMobileDeviceNameKey);
    await _prefs.setBool(_backupEnabledKey, false);
  }

  Future<void> clearDesktopReceiverPairing() async {
    await _prefs.remove(_backupAuthTokenKey);
    await _prefs.remove(_pairedDesktopIdKey);
    await _prefs.remove(_pairedMobileDeviceNameKey);
  }

  List<RecentSearch> get recentSearches {
    final raw = _prefs.getString(_recentSearchesKey);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => RecentSearch.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> addRecentSearch(RecentSearch entry) async {
    final current = recentSearches
        .where((s) => s.query.toLowerCase() != entry.query.toLowerCase())
        .toList();
    final next = [entry, ...current].take(_maxRecentSearches).toList();
    await _prefs.setString(
      _recentSearchesKey,
      jsonEncode(next.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> removeRecentSearch(String query) async {
    final next = recentSearches
        .where((s) => s.query.toLowerCase() != query.toLowerCase())
        .toList();
    await _prefs.setString(
      _recentSearchesKey,
      jsonEncode(next.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> clearRecentSearches() async {
    await _prefs.remove(_recentSearchesKey);
  }
}

