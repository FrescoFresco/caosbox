import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Opciones de Firebase para WEB, con soporte de --dart-define.
/// Si no vienen por define, usa los fallback aquí definidos.
class DefaultFirebaseOptions {
  static String _env(String key, String fallback) {
    // Ojo: el argumento del const debe ser literal, por eso no usamos variables.
    switch (key) {
      case 'FB_API_KEY':
        final v = const String.fromEnvironment('FB_API_KEY');
        return (v.isEmpty) ? fallback : v;
      case 'FB_APP_ID':
        final v = const String.fromEnvironment('FB_APP_ID');
        return (v.isEmpty) ? fallback : v;
      case 'FB_PROJECT_ID':
        final v = const String.fromEnvironment('FB_PROJECT_ID');
        return (v.isEmpty) ? fallback : v;
      case 'FB_MESSAGING_SENDER_ID':
        final v = const String.fromEnvironment('FB_MESSAGING_SENDER_ID');
        return (v.isEmpty) ? fallback : v;
      case 'FB_AUTH_DOMAIN':
        final v = const String.fromEnvironment('FB_AUTH_DOMAIN');
        return (v.isEmpty) ? fallback : v;
      case 'FB_STORAGE_BUCKET':
        final v = const String.fromEnvironment('FB_STORAGE_BUCKET');
        return (v.isEmpty) ? fallback : v;
      case 'FB_MEASUREMENT_ID':
        final v = const String.fromEnvironment('FB_MEASUREMENT_ID');
        return (v.isEmpty) ? fallback : v;
      default:
        return fallback;
    }
  }

  // Tus valores como fallback (puedes dejarlos así).
  static final FirebaseOptions web = FirebaseOptions(
    apiKey: _env('FB_API_KEY', 'AIzaSyBbpkoc4YlqfuYyM2TYASidFMOpeN9v2e4'),
    appId: _env('FB_APP_ID', '1:1087718443702:web:53c05e5ca672de14b5f417'),
    projectId: _env('FB_PROJECT_ID', 'caosbox-ef75b'),
    messagingSenderId: _env('FB_MESSAGING_SENDER_ID', '1087718443702'),
    authDomain: _env('FB_AUTH_DOMAIN', 'caosbox-ef75b.firebaseapp.com'),
    storageBucket: _env('FB_STORAGE_BUCKET', 'caosbox-ef75b.firebasestorage.app'),
    measurementId: _env('FB_MEASUREMENT_ID', 'G-8C1RD6K5Q5'),
  );

  static FirebaseOptions get currentPlatform {
    assert(kIsWeb, 'Este proyecto web solo usa configuración Web.');
    return web;
    // Si en el futuro compilas para móvil, añade aquí Android/iOS/MacOS.
  }
}
