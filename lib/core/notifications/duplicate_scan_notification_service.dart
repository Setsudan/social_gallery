import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:social_gallery/core/notifications/duplicate_scan_notification_throttle.dart';

const duplicateScanNotificationId = 1001;

const _channelId = 'duplicate_scan';
const _channelName = 'Duplicate scan';
const _channelDescription = 'Progress while searching for duplicate photos';

class DuplicateScanNotificationService {
  DuplicateScanNotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  var _initialized = false;
  var _permissionsRequested = false;
  var _appInForeground = true;
  var _duplicatesScreenVisible = false;
  var _scanActive = false;
  var _notificationVisible = false;
  var _lastScanned = 0;
  var _lastTotal = 0;

  bool get supportsNotifications =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> initialize() async {
    if (_initialized || !supportsNotifications) {
      return;
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.low,
      ),
    );

    _initialized = true;
  }

  Future<void> _ensurePermissions() async {
    if (_permissionsRequested || !supportsNotifications) {
      return;
    }
    _permissionsRequested = true;

    await initialize();

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(
      alert: true,
      badge: false,
      sound: false,
    );
  }

  void setAppInForeground(bool inForeground) {
    _appInForeground = inForeground;
    _syncProgressVisibility();
  }

  void setDuplicatesScreenVisible(bool visible) {
    _duplicatesScreenVisible = visible;
    _syncProgressVisibility();
  }

  void _syncProgressVisibility() {
    if (!_scanActive) {
      return;
    }

    if (_shouldShowProgress()) {
      unawaited(_showProgressIfNeeded(force: true));
      return;
    }

    unawaited(_hideProgress());
  }

  bool _shouldShowProgress() {
    return !_appInForeground || !_duplicatesScreenVisible;
  }

  Future<void> onScanStarted() async {
    if (!supportsNotifications) {
      return;
    }

    await _ensurePermissions();
    _scanActive = true;
    _lastScanned = 0;
    _lastTotal = 0;

    if (!_shouldShowProgress()) {
      return;
    }

    await _showProgressIfNeeded(
      force: true,
      title: 'Scanning for duplicates',
      body: 'Preparing duplicate scan...',
    );
  }

  Future<void> onScanProgress(int scanned, int total) async {
    if (!supportsNotifications || !_scanActive) {
      return;
    }

    _lastScanned = scanned;
    _lastTotal = total;

    if (!shouldEmitDuplicateScanProgressNotification(scanned, total)) {
      return;
    }

    if (!_shouldShowProgress() && !_notificationVisible) {
      return;
    }

    await _showProgressIfNeeded();
  }

  Future<void> onScanComplete(int groupCount) async {
    if (!supportsNotifications) {
      return;
    }

    _scanActive = false;
    await _plugin.cancel(id: duplicateScanNotificationId);
    _notificationVisible = false;

    if (!_shouldShowCompletion()) {
      return;
    }

    final title = groupCount == 0
        ? 'No duplicates found'
        : 'Duplicate scan complete';
    final body = groupCount == 0
        ? 'No near-identical photos were found in your library.'
        : 'Found $groupCount duplicate ${groupCount == 1 ? 'group' : 'groups'}.';

    await _showCompletion(title: title, body: body);
  }

  Future<void> onScanFailed(String message) async {
    if (!supportsNotifications) {
      return;
    }

    _scanActive = false;
    await _plugin.cancel(id: duplicateScanNotificationId);
    _notificationVisible = false;

    if (!_shouldShowCompletion()) {
      return;
    }

    await _showCompletion(
      title: 'Duplicate scan failed',
      body: 'Could not finish scanning. Open Duplicates to try again.',
    );
  }

  bool _shouldShowCompletion() {
    return _shouldShowProgress() || _notificationVisible;
  }

  Future<void> _showProgressIfNeeded({
    bool force = false,
    String? title,
    String? body,
  }) async {
    if (!_scanActive) {
      return;
    }

    if (!_shouldShowProgress() && !force) {
      return;
    }

    final resolvedTitle = title ?? 'Scanning for duplicates';
    final resolvedBody = body ?? _progressBody(_lastScanned, _lastTotal);

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.low,
      priority: Priority.low,
      onlyAlertOnce: true,
      ongoing: true,
      showProgress: _lastTotal > 0,
      maxProgress: _lastTotal > 0 ? _lastTotal : 0,
      progress: _lastTotal > 0 ? _lastScanned : 0,
      indeterminate: _lastTotal <= 0,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    await _plugin.show(
      id: duplicateScanNotificationId,
      title: resolvedTitle,
      body: resolvedBody,
      notificationDetails: NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
    _notificationVisible = true;
  }

  Future<void> _hideProgress() async {
    if (!_notificationVisible) {
      return;
    }

    await _plugin.cancel(id: duplicateScanNotificationId);
    _notificationVisible = false;
  }

  Future<void> _showCompletion({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      autoCancel: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    await _plugin.show(
      id: duplicateScanNotificationId,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
    );

    await Future<void>.delayed(const Duration(seconds: 4));
    await _plugin.cancel(id: duplicateScanNotificationId);
  }

  String _progressBody(int scanned, int total) {
    if (total <= 0) {
      return 'Preparing duplicate scan...';
    }
    return 'Analyzing $scanned / $total photos...';
  }
}
