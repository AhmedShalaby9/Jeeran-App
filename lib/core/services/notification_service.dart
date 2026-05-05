import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // ignore: avoid_print
  print('Background message: ${message.messageId} | ${message.notification?.title}');
}

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  bool _initialized = false;

  Future<void> init() async {
    // 1 — Firebase core
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } catch (e) {
      debugPrint('Firebase.initializeApp failed: $e');
      return;
    }

    _initialized = true;

    // 2 — Permission prompt (shows the iOS dialog)
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('requestPermission failed: $e');
    }

    // 3 — Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // 4 — Foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      // ignore: avoid_print
      print('Foreground notification: ${message.messageId} | ${message.notification?.title}');
    });

    // 5 — Tapped while app was in background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      // ignore: avoid_print
      print('Notification tapped (background): ${message.messageId} | ${message.notification?.title}');
    });

    // 6 — Tapped while app was terminated
    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        // ignore: avoid_print
        print('Notification tapped (terminated): ${initial.messageId} | ${initial.notification?.title}');
      }
    } catch (e) {
      debugPrint('getInitialMessage failed: $e');
    }
  }

  Future<String?> getToken() async {
    if (!_initialized) return null;
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('FCM getToken failed: $e');
      return null;
    }
  }
}
