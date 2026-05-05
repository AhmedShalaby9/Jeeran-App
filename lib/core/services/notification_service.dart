import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.messageId} | ${message.notification?.title}');
}

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  Future<void> init() async {
    await Firebase.initializeApp();

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // Foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      print('Foreground notification: ${message.messageId} | ${message.notification?.title}');
    });

    // Tapped while app was in background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('Notification tapped (background): ${message.messageId} | ${message.notification?.title}');
    });

    // Tapped while app was terminated
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      print('Notification tapped (terminated): ${initial.messageId} | ${initial.notification?.title}');
    }
  }

  Future<String?> getToken() => FirebaseMessaging.instance.getToken();
}
