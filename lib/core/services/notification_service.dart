import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.messageId}');
}

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  bool _initialized = false;
  final _readyCompleter = Completer<void>();
  Future<void> get ready => _readyCompleter.future;

  // Emits FCM data payload when user taps a notification
  final _tapController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get tapStream => _tapController.stream;

  // Emits when a foreground message arrives (for badge increment)
  final _foregroundController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get foregroundStream => _foregroundController.stream;

  Future<void> init() async {
    // 1 — Firebase core
    debugPrint('[FCM] init: starting Firebase.initializeApp');
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      debugPrint('[FCM] init: Firebase.initializeApp succeeded');
    } catch (e) {
      debugPrint('[FCM] init: Firebase.initializeApp FAILED: $e');
      _readyCompleter.completeError(e);
      return;
    }

    _initialized = true;
    debugPrint('[FCM] init: _initialized = true');

    // 2 — Permission prompt (shows the iOS dialog)
    try {
      debugPrint('[FCM] init: requesting permission...');
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('[FCM] init: permission status = ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint('[FCM] init: requestPermission FAILED: $e');
    }

    // 3 — Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // 4 — Foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      _foregroundController.add(message.data);
    });

    // 5 — Tapped while app was in background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _tapController.add(message.data);
    });

    // 6 — Tapped while app was terminated
    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        _tapController.add(initial.data);
      }
    } catch (e) {
      debugPrint('getInitialMessage failed: $e');
    }

    debugPrint('[FCM] init: ready');
    _readyCompleter.complete();
  }

  Future<String?> getToken() async {
    if (!_initialized) {
      debugPrint('[FCM] getToken: NOT initialized yet — returning null');
      return null;
    }
    try {
      // On iOS, APNs registration is async after permission grant; poll until ready
      if (Platform.isIOS) {
        for (int i = 0; i < 10; i++) {
          final apns = await FirebaseMessaging.instance.getAPNSToken();
          debugPrint('[FCM] getToken: APNs attempt ${i + 1} = $apns');
          if (apns != null) break;
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('[FCM] getToken: FCM token = $token');
      return token;
    } catch (e) {
      debugPrint('[FCM] getToken: FAILED: $e');
      return null;
    }
  }
}
