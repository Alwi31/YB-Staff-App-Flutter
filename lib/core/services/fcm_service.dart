import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:yb_staff_app/core/utils/navigator_key.dart';

// ── Background isolate handler ────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  // When the payload includes a `notification` block, the OS already renders
  // it automatically while the app is backgrounded/terminated. Showing it
  // again here would duplicate the popup, so only handle data-only messages.
  if (message.notification != null) return;

  final localNotif = FlutterLocalNotificationsPlugin();
  await localNotif.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/launcher_icon'),
      iOS: DarwinInitializationSettings(),
    ),
  );
  final title = message.notification?.title ??
      message.data['title'] as String? ??
      'Notifikasi Baru';
  final body = message.notification?.body ??
      message.data['message'] as String? ??
      message.data['body'] as String? ??
      '';
  await localNotif.show(
    message.hashCode,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'yb_staff_notif',
        'YukBersihin Staff',
        channelDescription: 'Notifikasi pekerjaan dan update order',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/launcher_icon',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      ),
    ),
  );
}

// ── Notification channel constants ────────────────────────────────────────────
const _kChannelId = 'yb_staff_notif';
const _kChannelName = 'YukBersihin Staff';
const _kChannelDesc = 'Notifikasi pekerjaan dan update order';

const _androidDetails = AndroidNotificationDetails(
  _kChannelId,
  _kChannelName,
  channelDescription: _kChannelDesc,
  importance: Importance.high,
  priority: Priority.high,
  playSound: true,
  enableVibration: true,
  icon: '@mipmap/launcher_icon',
);

const _notifDetails = NotificationDetails(
  android: _androidDetails,
  iOS: DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  ),
);

// ─────────────────────────────────────────────────────────────────────────────

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  bool _listenersRegistered = false;
  Future<void> Function(String token)? _onTokenReceived;
  VoidCallback? _onNewMessage;

  // ── Step 1: call from main() before runApp() ──────────────────────────────

  void setupBackgroundHandler() {
    try {
      FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);
    } catch (_) {}
  }

  // ── Step 2: call once on app start ───────────────────────────────────────

  Future<void> initNotifications({required VoidCallback onNewMessage}) async {
    _onNewMessage = onNewMessage;
    try {
      const androidInit =
          AndroidInitializationSettings('@mipmap/launcher_icon');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _localNotif.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
        onDidReceiveNotificationResponse: _onLocalNotifTap,
      );

      if (Platform.isAndroid) {
        final androidPlugin = _localNotif.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.createNotificationChannel(
          const AndroidNotificationChannel(
            _kChannelId,
            _kChannelName,
            description: _kChannelDesc,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );

        final granted = await androidPlugin?.areNotificationsEnabled() ?? true;
        if (!granted) {
          await androidPlugin?.requestNotificationsPermission();
        }
      }

      FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteNotifTap);

      final initial = await _messaging.getInitialMessage();
      if (initial != null) _handleRemoteNotifTap(initial);
    } catch (_) {}
  }

  // ── Step 3: call after user is authenticated ─────────────────────────────

  Future<void> requestPermissionAndRegister({
    required Future<void> Function(String token) onTokenReceived,
  }) async {
    _onTokenReceived = onTokenReceived;
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;

      if (!granted) return;

      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );

      if (!_listenersRegistered) {
        _listenersRegistered = true;

        _messaging.onTokenRefresh.listen(
          (token) {
            _onTokenReceived?.call(token).catchError((Object _) {});
          },
          onError: (Object _) {},
        );

        FirebaseMessaging.onMessage.listen(
          _onForegroundMessage,
          onError: (Object _) {},
        );
      }

      final token = await _messaging.getToken();
      if (token != null) {
        await onTokenReceived(token);
      }
    } catch (_) {}
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  void _onForegroundMessage(RemoteMessage message) {
    _onNewMessage?.call();

    final title = message.notification?.title ??
        message.data['title'] as String? ??
        'Notifikasi Baru';
    final body =
        message.notification?.body ?? message.data['message'] as String? ?? '';
    final payload = message.data['order_id']?.toString() ??
        message.data['job_id']?.toString();

    _localNotif
        .show(message.hashCode, title, body, _notifDetails, payload: payload)
        .catchError((Object _) {});
  }

  void _onLocalNotifTap(NotificationResponse response) =>
      _navigateToNotifications();

  void _handleRemoteNotifTap(RemoteMessage message) =>
      _navigateToNotifications();

  void _navigateToNotifications() {
    appNavigatorKey.currentState?.pushNamed('/notifications');
  }

  // ── Public helpers ────────────────────────────────────────────────────────

  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
    } catch (_) {}
  }
}
