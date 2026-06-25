import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError('Firebase is not configured for iOS yet.');
      case TargetPlatform.macOS:
        throw UnsupportedError('Firebase is not configured for macOS yet.');
      case TargetPlatform.windows:
        throw UnsupportedError('Firebase is not configured for Windows yet.');
      case TargetPlatform.linux:
        throw UnsupportedError('Firebase is not configured for Linux yet.');
      case TargetPlatform.fuchsia:
        throw UnsupportedError('Firebase is not configured for Fuchsia.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyChIjJ4bGd5UFAVpR60TNGsavBnuB-gbxQ',
    appId: '1:885458874704:android:3046e3f12a8aa4dd05bc55',
    messagingSenderId: '885458874704',
    projectId: 'orman-pazar',
    storageBucket: 'orman-pazar.firebasestorage.app',
    androidClientId: 'com.example.orman_pazar',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyChIjJ4bGd5UFAVpR60TNGsavBnuB-gbxQ',
    appId: '1:885458874704:android:3046e3f12a8aa4dd05bc55',
    messagingSenderId: '885458874704',
    projectId: 'orman-pazar',
    storageBucket: 'orman-pazar.firebasestorage.app',
  );
}
