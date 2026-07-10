import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tax_client/core/config/app_router.dart';
import 'package:tax_client/core/network/token_storage.dart';

/// Firebase Messaging + local notification display.
/// Persists device tokens via [TokenStorage]; does not call backend APIs.
class PushNotificationService {
  PushNotificationService(this._tokenStorage);

  final TokenStorage _tokenStorage;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final StreamController<String> _tokenController =
      StreamController<String>.broadcast();

  Stream<String> get onTokenUpdated => _tokenController.stream;

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;

  Future<void> initialize() async {
    await _requestPermission();
    await _initLocalNotifications();

    final token = await _firebaseMessaging.getToken();
    debugPrint('==================== FCM TOKEN ====================');
    debugPrint('FCM Token: $token');
    debugPrint('===================================================');
    if (token != null) {
      await _persistToken(token);
    }

    _tokenRefreshSubscription =
        _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      debugPrint('================ FCM TOKEN REFRESHED ===============');
      debugPrint('FCM Token Refreshed: $newToken');
      debugPrint('===================================================');
      await _persistToken(newToken);
    });

    _foregroundMessageSubscription =
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');
      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    _openedAppSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _handleNotificationTap(message.data);
    });

    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App opened from terminated state by a notification!');
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationTap(initialMessage.data);
      });
    }
  }

  Future<void> _persistToken(String token) async {
    await _tokenStorage.saveFcmToken(token);
    if (!_tokenController.isClosed) {
      _tokenController.add(token);
    }
    debugPrint('FCM Token stored locally.');
  }

  Future<void> _requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            _handleNotificationTap(data);
          } catch (e) {
            debugPrint('Error parsing notification payload: $e');
          }
        }
      },
    );

    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null && !kIsWeb) {
      const androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription:
            'This channel is used for important notifications.',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
      );

      const platformDetails = NotificationDetails(android: androidDetails);

      await _localNotificationsPlugin.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: platformDetails,
        payload: jsonEncode(message.data),
      );
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    debugPrint('Handling notification tap with data: $data');

    final router = AppRouter.router;
    if (router == null) {
      debugPrint('AppRouter.router is null, cannot navigate');
      return;
    }

    if (data.containsKey('route')) {
      final route = data['route'].toString();
      try {
        router.push(route);
      } catch (e) {
        debugPrint('Could not push route $route: $e');
      }
    }
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _foregroundMessageSubscription?.cancel();
    _openedAppSubscription?.cancel();
    _tokenController.close();
  }
}
