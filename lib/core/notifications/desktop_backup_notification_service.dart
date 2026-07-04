import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/core/notifications/notification_constants.dart';

const desktopBackupNotificationId = 1002;
const desktopBackupStallNotificationId = 1003;

const _progressChannelId = 'desktop_backup_progress';
const _progressChannelName = 'Backup progress';
const _progressChannelDescription =
    'Ongoing progress while backing up photos to your computer';

const _statusChannelId = 'desktop_backup_status';
const _statusChannelName = 'Backup results';
const _statusChannelDescription =
    'Backup completed, paused, or failed alerts';

const _successColor = Color(0xFF2E7D32);
const _errorColor = Color(0xFFC62828);
const _pausedColor = Color(0xFFEF6C00);

/// Ongoing notification and Android foreground service during LAN backup.
///
/// This is the sole UX surface for backup check/progress/result state: the
/// app shows no in-app banners or badges for these transient states, so every
/// meaningful transition must be reflected here.
class DesktopBackupNotificationService {
  DesktopBackupNotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  var _initialized = false;
  var _permissionsRequested = false;
  var _backupActive = false;
  var _foregroundServiceActive = false;
  var _notificationVisible = false;
  var _processed = 0;
  var _total = 0;
  var _detail = '';
  var _bytesSent = 0;
  var _bytesTotal = 0;
  var _phase = '';
  DateTime? _lastProgressUpdate;

  bool get supportsNotifications =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> initialize() async {
    if (_initialized || !supportsNotifications) {
      return;
    }

    const androidSettings =
        AndroidInitializationSettings(androidNotificationIcon);
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

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _progressChannelId,
        _progressChannelName,
        description: _progressChannelDescription,
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
        showBadge: false,
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _statusChannelId,
        _statusChannelName,
        description: _statusChannelDescription,
        importance: Importance.high,
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

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(
      alert: true,
      badge: false,
      sound: false,
    );
  }

  void setAppInForeground(bool inForeground) {
    unawaited(_syncVisibility());
  }

  Future<void> onBackupStarted() async {
    if (!supportsNotifications) {
      return;
    }

    await _ensurePermissions();
    _backupActive = true;
    _processed = 0;
    _total = 0;
    _detail = 'Preparing backup...';
    _bytesSent = 0;
    _bytesTotal = 0;
    _phase = '';
    _lastProgressUpdate = null;
    await _syncVisibility(force: true);
  }

  Future<void> onBackupProgress({
    required int processed,
    required int total,
    required String detail,
    int bytesSent = 0,
    int bytesTotal = 0,
    String phase = '',
    bool force = false,
  }) async {
    if (!supportsNotifications || !_backupActive) {
      return;
    }

    _processed = processed;
    _total = total;
    _detail = detail;
    _bytesSent = bytesSent;
    _bytesTotal = bytesTotal;
    _phase = phase;

    if (!force && !_shouldEmitProgressUpdate()) {
      return;
    }

    await _syncVisibility(force: true);
  }

  Future<void> onBackupStallWarning(String fileName) async {
    if (!supportsNotifications || !_backupActive) {
      return;
    }

    await _ensurePermissions();

    const title = 'Backup slow';
    final body = 'Transfer stalled on $fileName. Retrying...';

    final androidDetails = AndroidNotificationDetails(
      _statusChannelId,
      _statusChannelName,
      channelDescription: _statusChannelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      category: AndroidNotificationCategory.progress,
      visibility: NotificationVisibility.public,
      autoCancel: true,
      onlyAlertOnce: true,
      styleInformation: BigTextStyleInformation(body),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    await _plugin.show(
      id: desktopBackupStallNotificationId,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
    );
  }

  /// Ends the active backup run and reports its outcome.
  Future<void> onBackupStopped({
    String? completionTitle,
    String? completionBody,
    bool isError = false,
  }) async {
    if (!supportsNotifications) {
      return;
    }

    final wasActive = _backupActive;
    _backupActive = false;
    await _stopForegroundService();
    await _plugin.cancel(id: desktopBackupNotificationId);
    await _plugin.cancel(id: desktopBackupStallNotificationId);
    _notificationVisible = false;

    if (wasActive && completionTitle != null) {
      await _showBriefCompletion(
        title: completionTitle,
        body: completionBody ?? '',
        isError: isError,
      );
    }
  }

  bool _shouldEmitProgressUpdate() {
    final now = DateTime.now();
    final last = _lastProgressUpdate;
    if (last == null || now.difference(last) >= const Duration(seconds: 1)) {
      _lastProgressUpdate = now;
      return true;
    }
    return false;
  }

  Future<void> _syncVisibility({bool force = false}) async {
    if (!_backupActive) {
      return;
    }

    if (_shouldShowNotification() || force) {
      await _showProgress(force: force);
      return;
    }

    await _stopForegroundService();
    if (_notificationVisible) {
      await _plugin.cancel(id: desktopBackupNotificationId);
      _notificationVisible = false;
    }
  }

  bool _shouldShowNotification() {
    return true;
  }

  Future<void> _showProgress({bool force = false}) async {
    if (!_backupActive) {
      return;
    }

    if (!_shouldShowNotification() && !force) {
      return;
    }

    final title = 'Backup in progress';
    final body = _progressBody();

    if (Platform.isAndroid) {
      final androidDetails = AndroidNotificationDetails(
        _progressChannelId,
        _progressChannelName,
        channelDescription: _progressChannelDescription,
        importance: Importance.low,
        priority: Priority.low,
        onlyAlertOnce: true,
        ongoing: true,
        silent: true,
        category: AndroidNotificationCategory.progress,
        visibility: NotificationVisibility.public,
        ticker: title,
        groupKey: 'desktop_backup',
        showProgress: _total > 0,
        maxProgress: _total > 0 ? _total : 0,
        progress: _total > 0 ? _processed : 0,
        indeterminate: _total <= 0,
        styleInformation: BigTextStyleInformation(body),
      );

      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (!_foregroundServiceActive) {
        await androidPlugin?.startForegroundService(
          id: desktopBackupNotificationId,
          title: title,
          body: body,
          notificationDetails: androidDetails,
          foregroundServiceTypes: {
            AndroidServiceForegroundType.foregroundServiceTypeDataSync,
          },
        );
        _foregroundServiceActive = true;
      } else {
        await _plugin.show(
          id: desktopBackupNotificationId,
          title: title,
          body: body,
          notificationDetails: NotificationDetails(android: androidDetails),
        );
      }
      _notificationVisible = true;
      return;
    }

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    await _plugin.show(
      id: desktopBackupNotificationId,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(iOS: iosDetails),
    );
    _notificationVisible = true;
  }

  Future<void> _stopForegroundService() async {
    if (!Platform.isAndroid || !_foregroundServiceActive) {
      return;
    }

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.stopForegroundService();
    _foregroundServiceActive = false;
  }

  Future<void> _showBriefCompletion({
    required String title,
    required String body,
    required bool isError,
  }) async {
    final isPaused = !isError && title.toLowerCase().contains('paused');
    final color = isError
        ? _errorColor
        : isPaused
            ? _pausedColor
            : _successColor;

    final androidDetails = AndroidNotificationDetails(
      _statusChannelId,
      _statusChannelName,
      channelDescription: _statusChannelDescription,
      importance: isError ? Importance.high : Importance.defaultImportance,
      priority: isError ? Priority.high : Priority.defaultPriority,
      category: isError
          ? AndroidNotificationCategory.error
          : AndroidNotificationCategory.status,
      visibility: NotificationVisibility.public,
      autoCancel: true,
      color: color,
      styleInformation: body.isNotEmpty
          ? BigTextStyleInformation(body)
          : null,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: isError,
    );

    await _plugin.show(
      id: desktopBackupNotificationId,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
    );

    await Future<void>.delayed(const Duration(seconds: 4));
    await _plugin.cancel(id: desktopBackupNotificationId);
  }

  String _progressBody() {
    if (_detail.isNotEmpty) {
      return _detail;
    }
    if (_total > 0) {
      final base = 'Backed up $_processed / $_total items';
      if (_bytesTotal > 0) {
        final filePercent = ((_bytesSent / _bytesTotal) * 100).round();
        final phaseLabel = _phaseLabel();
        if (phaseLabel.isNotEmpty) {
          return '$base - $phaseLabel ($filePercent%)';
        }
        return '$base ($filePercent%)';
      }
      return base;
    }
    return 'Preparing backup...';
  }

  String _phaseLabel() {
    return switch (_phase) {
      'preparing' => 'Preparing file',
      'uploading' => 'Uploading',
      'completing' => 'Finishing',
      _ => '',
    };
  }
}

final desktopBackupNotificationServiceProvider =
    Provider<DesktopBackupNotificationService>(
  (ref) => DesktopBackupNotificationService(),
);
