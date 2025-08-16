// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

const _API_KEY     = String.fromEnvironment('FB_API_KEY', defaultValue: '');
const _APP_ID      = String.fromEnvironment('FB_APP_ID', defaultValue: '');
const _PROJECT_ID  = String.fromEnvironment('FB_PROJECT_ID', defaultValue: '');
const _SENDER_ID   = String.fromEnvironment('FB_MESSAGING_SENDER_ID', defaultValue: '');
const _AUTH_DOMAIN = String.fromEnvironment('FB_AUTH_DOMAIN', defaultValue: '');
const _BUCKET      = String.fromEnvironment('FB_STORAGE_BUCKET', defaultValue: '');
const _MEASURE_ID  = String.fromEnvironment('FB_MEASUREMENT_ID', defaultValue: '');

void _require(String v, String name) {
  if (v.isEmpty) {
    throw FlutterError('Falta definir --dart-define=$name en el build.');
  }
}

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Validaciones mínimas (todas necesarias para Web)
    _require(_API_KEY, 'FB_API_KEY');
    _require(_APP_ID, 'FB_APP_ID');
    _require(_PROJECT_ID, 'FB_PROJECT_ID');
    _require(_SENDER_ID, 'FB_MESSAGING_SENDER_ID');
    _require(_AUTH_DOMAIN, 'FB_AUTH_DOMAIN');
    _require(_BUCKET, 'FB_STORAGE_BUCKET');
    // measurementId puede estar vacío si no usas Analytics

    return FirebaseOptions(
      apiKey: _API_KEY,
      appId: _APP_ID,
      projectId: _PROJECT_ID,
      messagingSenderId: _SENDER_ID,
      authDomain: _AUTH_DOMAIN,
      storageBucket: _BUCKET,
      measurementId: _MEASURE_ID.isEmpty ? null : _MEASURE_ID,
    );
  }
}
