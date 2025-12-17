import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

class NotificationHandler {
  @pragma('vm:entry-point') // Ensure the handler is kept for background isolates.
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    debugPrint('[FCM][BACKGROUND] Title: ${message.notification?.title}, Body: ${message.notification?.body}, Data: ${message.data}');
    // TODO: Add navigation logic if needed (background)
  }

  final FlutterLocalNotificationsPlugin _localNotification = FlutterLocalNotificationsPlugin();
  final AndroidNotificationChannel _androidChannel = const AndroidNotificationChannel(
    'channel_notification',
    'High Importance Notification',
    description: 'Used For Notification',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    sound: RawResourceAndroidNotificationSound('suara'),
  );
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initPushNotification() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');
    _firebaseMessaging.getToken().then((token) {
      debugPrint('[FCM] Token: $token');
    });
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint('[FCM][TERMINATED] Title: ${message.notification?.title}, Body: ${message.notification?.body}, Data: ${message.data}');
        _handleNotificationNavigation(message.data);
      } else {
        debugPrint('[FCM][TERMINATED] No initial message');
      }
    });
    FirebaseMessaging.onBackgroundMessage(NotificationHandler.firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      debugPrint('[FCM][FOREGROUND] Title: ${notification?.title}, Body: ${notification?.body}, Data: ${message.data}');
      if (notification == null) return;
      _localNotification.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('suara'),
          ),
        ),
        payload: jsonEncode(message.data),
      );
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM][CLICK] Title: ${message.notification?.title}, Body: ${message.notification?.body}, Data: ${message.data}');
      _handleNotificationNavigation(message.data);
    });
  }

  Future<void> initLocalNotification() async {
    tz_data.initializeTimeZones();
    try {
      final dynamic localTimezone = await FlutterTimezone.getLocalTimezone();
      String timeZoneName;
      if (localTimezone is String) {
        timeZoneName = localTimezone;
      } else {
        try {
          timeZoneName = localTimezone.id;
        } catch (_) {
          final str = localTimezone.toString();
          if (str.startsWith('TimezoneInfo(')) {
            timeZoneName = str.split(',')[0].substring(13);
          } else {
            timeZoneName = 'UTC';
          }
        }
      }
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('Error setting local timezone: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
    const ios = DarwinInitializationSettings();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android, iOS: ios);
    await _localNotification.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('[LOCAL][CLICK] Notification payload: ${details.payload}');
        if (details.payload != null && details.payload!.isNotEmpty) {
          try {
            final data = jsonDecode(details.payload!);
            _handleNotificationNavigation(data);
          } catch (e) {
            debugPrint('[LOCAL][CLICK] Failed to parse payload: $e');
          }
        }
      },
    );
    await _localNotification.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(_androidChannel);
  }

  /// Jadwalkan pengingat lokal (mis. isi mood/journal) pada waktu tertentu zona lokal.
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
    await _localNotification.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('suara'),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // ulangi harian di jam sama
    );
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final route = data['route'];
    if (route != null && route != '/home') {
      Get.toNamed(route, arguments: data);
      debugPrint('[NAVIGATION] Navigated to $route with data: $data');
    } else {
      debugPrint('[NAVIGATION] No valid route in payload or route is /home. Data: $data');
    }
  }

  Future<void> showNotification({required String title, required String body}) async {
    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'channel_notification',
      'High Importance Notification',
      channelDescription: 'Used For Notification',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const iOSPlatformChannelSpecifics = DarwinNotificationDetails();
    const platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    await _localNotification.show(
      DateTime.now().millisecond,
      title,
      body,
      platformChannelSpecifics,
      payload: 'plain notification',
    );
  }

  Future<void> showCustomSoundNotification() async {
    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'custom_sound_channel',
      'Custom Sound Notification',
      channelDescription: 'Notifications with custom sound',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      sound: RawResourceAndroidNotificationSound('suara'),
      playSound: true,
    );
    const iOSPlatformChannelSpecifics = DarwinNotificationDetails(
      sound: 'suara.mp3',
    );
    const platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    await _localNotification.show(
      DateTime.now().millisecond,
      'Custom Sound Notification',
      'This is a notification with a custom sound!',
      platformChannelSpecifics,
      payload: 'custom_sound',
    );
  }
}
