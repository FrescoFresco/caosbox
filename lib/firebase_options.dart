// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Solo soportamos Web (tu caso de GitHub Pages)
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: String.fromEnvironment('FB_API_KEY'),
    appId: String.fromEnvironment('FB_APP_ID'),
    projectId: String.fromEnvironment('FB_PROJECT_ID'),
    messagingSenderId: String.fromEnvironment('FB_MESSAGING_SENDER_ID'),
    authDomain: String.fromEnvironment('FB_AUTH_DOMAIN'),
    storageBucket: String.fromEnvironment('FB_STORAGE_BUCKET'),
    measurementId: String.fromEnvironment('FB_MEASUREMENT_ID'),
  );
}
