import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../routing/app_router.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class FcmService {
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<String>? _tokenRefreshSubscription;

  Future<void> initialize() async {
    // Firebase.initializeApp() must already have been called from main().
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const channel = AndroidNotificationChannel(
      'golddesk_alerts',
      'GoldDesk alerts',
      description: 'Order, message, and business alerts',
      importance: Importance.high,
    );
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(channel);
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(
      (_) => AppRouter.router.go('/notifications'),
    );

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      AppRouter.router.go('/notifications');
    }
  }

  Future<String?> getToken() => _messaging.getToken();

  Future<void> clearDeviceToken() async {
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    await _messaging.deleteToken();
  }

  void listenForTokenRefresh(Future<void> Function(String token) onRefresh) {
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
      (token) => onRefresh(token),
    );
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'golddesk_alerts',
          'GoldDesk alerts',
          channelDescription: 'Order, message, and business alerts',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: message.data['orderId'],
    );
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
  }
}
