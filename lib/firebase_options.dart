// File: lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
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

  // For web-only, we can just return web directly
  static FirebaseOptions get currentPlatform => web;
}