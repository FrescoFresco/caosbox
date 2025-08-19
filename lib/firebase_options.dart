// lib/firebase_options.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';

/// Lee variables de entorno del build (--dart-define) como constantes.
/// NOTA: la clave debe ser literal, por eso NO usamos una función genérica.
class DefaultFirebaseOptions {
  // Valores leídos en tiempo de compilación desde --dart-define
  static const String _apiKey =
      String.fromEnvironment('FB_API_KEY', defaultValue: '');
  static const String _appId =
      String.fromEnvironment('FB_APP_ID', defaultValue: '');
  static const String _projectId =
      String.fromEnvironment('FB_PROJECT_ID', defaultValue: '');
  static const String _senderId =
      String.fromEnvironment('FB_MESSAGING_SENDER_ID', defaultValue: '');
  static const String _authDomain =
      String.fromEnvironment('FB_AUTH_DOMAIN', defaultValue: '');
  static const String _storageBucket =
      String.fromEnvironment('FB_STORAGE_BUCKET', defaultValue: '');
  static const String _measurementId =
      String.fromEnvironment('FB_MEASUREMENT_ID', defaultValue: '');

  /// Usa esta propiedad desde main.dart
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError('Solo está soportada la plataforma Web en este proyecto.');
  }

  /// Config para Web. Campos *obligatorios* siempre no nulos (Strings).
  static FirebaseOptions get web {
    // Validación defensiva para que, si falta algo, falle con mensaje claro en runtime.
    if (_apiKey.isEmpty ||
        _appId.isEmpty ||
        _projectId.isEmpty ||
        _senderId.isEmpty) {
      throw StateError(
        'Faltan variables de entorno de Firebase. Revisa los --dart-define: '
        'FB_API_KEY, FB_APP_ID, FB_PROJECT_ID, FB_MESSAGING_SENDER_ID.',
      );
    }

    return FirebaseOptions(
      apiKey: _apiKey,
      appId: _appId,
      projectId: _projectId,
      messagingSenderId: _senderId,              // ← requerido y NO nulo
      authDomain: _authDomain.isEmpty ? null : _authDomain,
      storageBucket: _storageBucket.isEmpty ? null : _storageBucket,
      measurementId: _measurementId.isEmpty ? null : _measurementId,
    );
  }
}
