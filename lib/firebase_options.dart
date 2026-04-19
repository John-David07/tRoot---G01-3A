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
        return windows;
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
    apiKey: 'AIzaSyDzB68_T2TNVzZ3zAAryhGAAiNJ2B_EFX0',
    appId: '1:1000733014035:web:a543517c78c1d8ed5ce7e6',
    messagingSenderId: '1000733014035',
    projectId: 'moisture-detector---esp3-6a1f6',
    authDomain: 'moisture-detector---esp3-6a1f6.firebaseapp.com',
    databaseURL: 'https://moisture-detector---esp3-6a1f6-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'moisture-detector---esp3-6a1f6.firebasestorage.app',
    measurementId: 'G-LPH0J96CMT',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDzB68_T2TNVzZ3zAAryhGAAiNJ2B_EFX0',
    appId: '1:1000733014035:android:19235fdf5198971b0d45c2',
    messagingSenderId: '1000733014035',
    projectId: 'moisture-detector---esp3-6a1f6',
    databaseURL: 'https://moisture-detector---esp3-6a1f6-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'moisture-detector---esp3-6a1f6.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDzB68_T2TNVzZ3zAAryhGAAiNJ2B_EFX0',
    appId: '1:1000733014035:ios:YOUR_IOS_APP_ID',
    messagingSenderId: '1000733014035',
    projectId: 'moisture-detector---esp3-6a1f6',
    databaseURL: 'https://moisture-detector---esp3-6a1f6-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'moisture-detector---esp3-6a1f6.firebasestorage.app',
    iosBundleId: 'com.example.flutterApplication1',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDzB68_T2TNVzZ3zAAryhGAAiNJ2B_EFX0',
    appId: '1:1000733014035:ios:YOUR_IOS_APP_ID',
    messagingSenderId: '1000733014035',
    projectId: 'moisture-detector---esp3-6a1f6',
    databaseURL: 'https://moisture-detector---esp3-6a1f6-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'moisture-detector---esp3-6a1f6.firebasestorage.app',
    iosBundleId: 'com.example.flutterApplication1',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDzB68_T2TNVzZ3zAAryhGAAiNJ2B_EFX0',
    appId: '1:1000733014035:web:a543517c78c1d8ed5ce7e6',
    messagingSenderId: '1000733014035',
    projectId: 'moisture-detector---esp3-6a1f6',
    authDomain: 'moisture-detector---esp3-6a1f6.firebaseapp.com',
    databaseURL: 'https://moisture-detector---esp3-6a1f6-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'moisture-detector---esp3-6a1f6.firebasestorage.app',
    measurementId: 'G-LPH0J96CMT',
  );
}