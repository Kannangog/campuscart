import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBrGF1qf0d5XK0Vn9TJAFg-ncG-ZrApzGQ',
    appId: '1:814733677259:web:f6eeef48566539b9b5814e',
    messagingSenderId: '814733677259',
    projectId: 'campuscart-23e57',
    authDomain: 'campuscart-23e57.firebaseapp.com',
    storageBucket: 'campuscart-23e57.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBrGF1qf0d5XK0Vn9TJAFg-ncG-ZrApzGQ',
    appId: '1:814733677259:android:f6eeef48566539b9b5814e',
    messagingSenderId: '814733677259',
    projectId: 'campuscart-23e57',
    storageBucket: 'campuscart-23e57.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBrGF1qf0d5XK0Vn9TJAFg-ncG-ZrApzGQ',
    appId: '1:814733677259:ios:f6eeef48566539b9b5814e',
    messagingSenderId: '814733677259',
    projectId: 'campuscart-23e57',
    storageBucket: 'campuscart-23e57.appspot.com',
    iosBundleId: 'com.example.campuscart',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBrGF1qf0d5XK0Vn9TJAFg-ncG-ZrApzGQ',
    appId: '1:814733677259:ios:f6eeef48566539b9b5814e',
    messagingSenderId: '814733677259',
    projectId: 'campuscart-23e57',
    storageBucket: 'campuscart-23e57.appspot.com',
    iosBundleId: 'com.example.campuscart',
  );
}