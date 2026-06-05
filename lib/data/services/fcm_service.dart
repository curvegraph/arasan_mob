import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'api_service.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print('Background message: ${message.messageId}');
  }
}

/// FCM Service for handling push notifications
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isInitialized = false;

  // Callback for navigation when notification is tapped
  Function(String? orderId)? onNotificationTap;

  // Notification channel for Android
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'orders',
    'Order Notifications',
    description: 'Notifications for order status updates',
    importance: Importance.high,
    playSound: true,
  );

  /// Initialize FCM service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Set background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print('FCM permission status: ${settings.authorizationStatus}');
      }

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Initialize local notifications
        await _initializeLocalNotifications();

        // Get and save FCM token
        await _getAndSaveToken();

        // Listen for token refresh
        _messaging.onTokenRefresh.listen(_saveTokenToSupabase);

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle notification tap when app is in background
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

        // Check for initial message (app opened from terminated state)
        final initialMessage = await _messaging.getInitialMessage();
        if (initialMessage != null) {
          _handleNotificationTap(initialMessage);
        }

        _isInitialized = true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('FCM initialization error: $e');
      }
    }
  }

  /// Initialize local notifications for foreground display
  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
        if (details.payload != null) {
          try {
            final data = jsonDecode(details.payload!) as Map<String, dynamic>;
            _navigateFromNotification(data);
          } catch (_) {}
        }
      },
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }
  }

  /// Get FCM token and save to Supabase
  Future<void> _getAndSaveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToSupabase(token);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
    }
  }

  /// Register FCM token with the backend.
  Future<void> _saveTokenToSupabase(String token) async {
    try {
      if (_supabase.auth.currentUser == null) return;
      await ApiService().post('/notifications/register-device',
          body: {
            'fcmToken': token,
            'deviceType': 'mobile',
          },
          requireAuth: true);
      if (kDebugMode) print('FCM token registered with backend');
    } catch (e) {
      if (kDebugMode) print('Error registering FCM token: $e');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('Foreground message: ${message.messageId}');
    }

    final notification = message.notification;
    final android = message.notification?.android;

    // Show local notification
    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      print('Notification tapped: ${message.data}');
    }
    _navigateFromNotification(message.data);
  }

  /// Navigate based on notification data
  void _navigateFromNotification(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final orderId = data['order_id'] as String?;

    if (type != null && type.startsWith('order_') && orderId != null) {
      // Call the navigation callback
      onNotificationTap?.call(orderId);
    }
  }

  /// Update FCM token when user logs in
  Future<void> updateTokenOnLogin() async {
    if (_isInitialized) {
      await _getAndSaveToken();
    }
  }

  /// Clear FCM token on logout
  Future<void> clearToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null && _supabase.auth.currentUser != null) {
        await ApiService().post('/notifications/unregister-device',
            body: {'fcmToken': token}, requireAuth: true);
      }

      await _messaging.deleteToken();
      if (kDebugMode) print('FCM token cleared');
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing FCM token: $e');
      }
    }
  }

  /// Subscribe to topic (e.g., for promotional notifications)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
    } catch (e) {
      if (kDebugMode) {
        print('Error subscribing to topic: $e');
      }
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } catch (e) {
      if (kDebugMode) {
        print('Error unsubscribing from topic: $e');
      }
    }
  }
}
