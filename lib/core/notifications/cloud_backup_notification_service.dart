import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:social_gallery/core/notifications/notification_constants.dart';

const cloudBackupNotificationId = 1012;

const _progressChannelId = 'cloud_backup_progress';
const _progressChannelName = 'Cloud backup progress';
const _progressChannelDescription =
    'Ongoing progress while encrypting and uploading to cloud storage';

const _statusChannelId = 'cloud_backup_status';
const _statusChannelName = 'Cloud backup results';
const _statusChannelDescription = 'Cloud backup completed or failed alerts';

const _successColor = Color(0xFF2E7D32);
const _errorColor = Color(0xFFC62828);

/// Notifications for encrypted cloud backup progress.
class CloudBackupNotificationService {
  CloudBackupNotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  var _initialized = false;
  var _permissionsRequested = false;
  var _active = false;

  bool get supportsNotifications =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> initialize() async {
    if (_initialized || !supportsNotifications) return;

    const androidSettings = AndroidInitializationSettings(
      androidNotificationIcon,
    );
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
          AndroidFlutterLocalNotificationsPlugin
        >();
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
    if (_permissionsRequested || !supportsNotifications) return;
    _permissionsRequested = true;
    await initialize();
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosPlugin?.requestPermissions(
      alert: true,
      badge: false,
      sound: false,
    );
  }

  Future<void> onBackupStarted() async {
    if (!supportsNotifications) return;
    await _ensurePermissions();
    _active = true;
    await _showProgress(title: 'Cloud backup', body: 'Preparing…', progress: 0);
  }

  Future<void> onBackupProgress({
    required int processed,
    required int total,
    required String detail,
    int? bytesSent,
    int? bytesTotal,
  }) async {
    if (!supportsNotifications || !_active) return;
    final pct = total > 0 ? ((processed / total) * 100).round() : 0;
    var body = detail.isNotEmpty ? detail : '$processed / $total';
    if (bytesSent != null && bytesTotal != null && bytesTotal > 0) {
      final filePct = ((bytesSent / bytesTotal) * 100).round();
      body = '$body ($filePct%)';
    }
    await _showProgress(
      title: 'Cloud backup ($pct%)',
      body: body,
      progress: pct.clamp(0, 100),
    );
  }

  Future<void> onBackupFinished({
    required bool success,
    String? message,
  }) async {
    if (!supportsNotifications) return;
    _active = false;
    await _plugin.cancel(id: cloudBackupNotificationId);
    await _plugin.show(
      id: cloudBackupNotificationId + 1,
      title: success ? 'Cloud backup complete' : 'Cloud backup failed',
      body:
          message ??
          (success ? 'Media encrypted and uploaded.' : 'Try again later.'),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _statusChannelId,
          _statusChannelName,
          channelDescription: _statusChannelDescription,
          importance: Importance.high,
          color: success ? _successColor : _errorColor,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> onBackupStopped() async {
    _active = false;
    if (!supportsNotifications) return;
    await _plugin.cancel(id: cloudBackupNotificationId);
  }

  Future<void> _showProgress({
    required String title,
    required String body,
    required int progress,
  }) async {
    await _plugin.show(
      id: cloudBackupNotificationId,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _progressChannelId,
          _progressChannelName,
          channelDescription: _progressChannelDescription,
          importance: Importance.low,
          onlyAlertOnce: true,
          showProgress: true,
          maxProgress: 100,
          progress: progress,
          ongoing: true,
          playSound: false,
          enableVibration: false,
        ),
        iOS: const DarwinNotificationDetails(presentAlert: false),
      ),
    );
  }
}
