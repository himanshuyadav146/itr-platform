import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tax_client/core/config/app_router.dart';
import 'package:tax_client/core/network/token_storage.dart';
import 'dart:convert';

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static TokenStorage? _tokenStorage;

  static Future<void> init(TokenStorage tokenStorage) async {
    _tokenStorage = tokenStorage;

    // 1. Request permissions for iOS and Android 13+
    await _requestPermission();

    // 2. Initialize local notifications for foreground messages
    await _initLocalNotifications();

    // 3. Get the FCM token and store it locally for later backend registration on login
    String? token = await _firebaseMessaging.getToken();
    debugPrint("==================== FCM TOKEN ====================");
    debugPrint("FCM Token: $token");
    debugPrint("===================================================");
    if (token != null) {
      await _storeTokenLocally(token);
    }

    // Listen to token refresh — update local storage
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      debugPrint("================ FCM TOKEN REFRESHED ===============");
      debugPrint("FCM Token Refreshed: $newToken");
      debugPrint("===================================================");
      _storeTokenLocally(newToken);
    });

    // 4. Handle incoming messages while the app is in Foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint(
          'Message also contained a notification: ${message.notification}',
        );
        _showLocalNotification(message);
      }
    });

    // 5. Handle tapping a notification when the app is in the Background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _handleNotificationTap(message.data);
    });

    // 6. Handle tapping a notification when the app is completely Terminated
    RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App opened from terminated state by a notification!');
      // Need a slight delay to allow router to initialize if needed
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationTap(initialMessage.data);
      });
    }
  }

  /// Store FCM token locally so it can be sent to backend after login
  static Future<void> _storeTokenLocally(String token) async {
    if (_tokenStorage == null) return;
    await _tokenStorage!.saveFcmToken(token);
    debugPrint("FCM Token stored locally.");
  }

  /// Get the locally stored FCM token (called by login flow to register with backend)
  static Future<String?> getStoredFcmToken() async {
    if (_tokenStorage == null) return null;
    return await _tokenStorage!.getFcmToken();
  }

  static Future<void> _requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
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

  static Future<void> _initLocalNotifications() async {
    // Initialization settings for Android
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    // Initialization settings for iOS
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
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
            debugPrint("Error parsing notification payload: $e");
          }
        }
      },
    );

    // Create a high importance channel for Android heads-up notifications
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // name
      description:
          'This channel is used for important notifications.', // description
      importance: Importance.max,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null && !kIsWeb) {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'high_importance_channel', // Must match the channel id above
            'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications.',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/launcher_icon',
          );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      await _localNotificationsPlugin.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: platformDetails,
        payload: jsonEncode(message.data),
      );
    }
  }

  static void _handleNotificationTap(Map<String, dynamic> data) {
    // Determine where to navigate based on the payload data
    debugPrint("Handling notification tap with data: $data");

    // Example: { "route": "/orders", "orderId": "123" }
    final router = AppRouter.router;
    if (router != null) {
      if (data.containsKey('route')) {
        String route = data['route'].toString();

        // Append query params if needed, or parse them from data
        try {
          router.push(route);
        } catch (e) {
          debugPrint("Could not push route $route: $e");
        }
      } else {
        // Default navigation or ignore if no specific route provided
        // e.g., router.go('/');
      }
    } else {
      debugPrint("AppRouter.router is null, cannot navigate");
    }
  }
}
