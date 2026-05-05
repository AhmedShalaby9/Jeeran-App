import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA2wFEmMGKxs82LHlFUwa4bztB5HHYFKx0',
    appId: '1:844365789676:android:dc96acb038bcd9474e28c9',
    messagingSenderId: '844365789676',
    projectId: 'studio-6503153993-be5d6',
    storageBucket: 'studio-6503153993-be5d6.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCkM_KFDO4wm4HBfRX6DAbUri7BCitJU2w',
    appId: '1:844365789676:ios:67dfd55d699a3b624e28c9',
    messagingSenderId: '844365789676',
    projectId: 'studio-6503153993-be5d6',
    storageBucket: 'studio-6503153993-be5d6.firebasestorage.app',
    iosBundleId: 'com.jeeran.realestate',
  );
}
