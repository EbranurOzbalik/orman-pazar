import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

// Temporary placeholder for local development.
// Run `flutterfire configure` later; FlutterFire CLI will replace this file
// with real Firebase project settings.
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
        return linux;
      case TargetPlatform.fuchsia:
        throw UnsupportedError('Firebase is not configured for Fuchsia.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'placeholder-api-key',
    appId: '1:1234567890:android:placeholder',
    messagingSenderId: '1234567890',
    projectId: 'orman-pazar-placeholder',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'placeholder-api-key',
    appId: '1:1234567890:ios:placeholder',
    messagingSenderId: '1234567890',
    projectId: 'orman-pazar-placeholder',
    iosBundleId: 'com.example.ormanPazar',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'placeholder-api-key',
    appId: '1:1234567890:web:placeholder',
    messagingSenderId: '1234567890',
    projectId: 'orman-pazar-placeholder',
    authDomain: 'orman-pazar-placeholder.firebaseapp.com',
    storageBucket: 'orman-pazar-placeholder.appspot.com',
  );

  static const FirebaseOptions macos = ios;

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'placeholder-api-key',
    appId: '1:1234567890:web:placeholder',
    messagingSenderId: '1234567890',
    projectId: 'orman-pazar-placeholder',
    authDomain: 'orman-pazar-placeholder.firebaseapp.com',
    storageBucket: 'orman-pazar-placeholder.appspot.com',
  );

  static const FirebaseOptions linux = windows;
}
