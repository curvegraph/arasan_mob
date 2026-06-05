import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are only configured for Android and iOS.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAamLnOVJuI7Ap7C6aAmMCuWwdFkpWXLps',
    appId: '1:841753792573:android:bc93381964772c6d6b5a54',
    messagingSenderId: '841753792573',
    projectId: 'arasan-mobiles-in',
    storageBucket: 'arasan-mobiles-in.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA_7QMxVolvki_YR02JfUZhsT-lKKhw65E',
    appId: '1:841753792573:ios:e8eef2969ab2cb7b6b5a54',
    messagingSenderId: '841753792573',
    projectId: 'arasan-mobiles-in',
    storageBucket: 'arasan-mobiles-in.firebasestorage.app',
    iosBundleId: 'com.arasanmobiles.arasanUser',
  );
}
