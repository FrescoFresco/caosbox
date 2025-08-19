// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

/// Lee valores de --dart-define en build time.
String _env(String k) => const String.fromEnvironment(k, defaultValue: '');

class OptionsFromEnv {
  final FirebaseOptions web = FirebaseOptions(
    apiKey: _env('FB_API_KEY'),
    appId: _env('FB_APP_ID'),
    messagingSenderId: _env('FB_MESSAGING_SENDER_ID'),
    projectId: _env('FB_PROJECT_ID'),
    authDomain: _env('FB_AUTH_DOMAIN'),
    storageBucket: _env('FB_STORAGE_BUCKET'),
    measurementId: _env('FB_MEASUREMENT_ID'),
  );
}

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    final o = OptionsFromEnv();
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        // Si quisieras soportar móviles/escritorio, añade aquí los Options específicos.
        return o.web;
      case TargetPlatform.values:
        return o.web;
    }
  }
}
