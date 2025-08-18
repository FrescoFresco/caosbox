// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart';

/// Lee variables pasadas con --dart-define y construye las opciones de Firebase.
/// Este archivo está pensado para **Web**.
class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform => web;

  // Helper para leer del entorno con fallback.
  static String _env(String key, {String def = ''}) =>
      String.fromEnvironment(key, defaultValue: def);

  // Opciones para Web.
  static final FirebaseOptions web = FirebaseOptions(
    apiKey: _env('FB_API_KEY'),
    appId: _env('FB_APP_ID'),
    projectId: _env('FB_PROJECT_ID'),
    messagingSenderId: _env('FB_MESSAGING_SENDER_ID'),
    authDomain: _env('FB_AUTH_DOMAIN'),
    storageBucket: _env('FB_STORAGE_BUCKET'),
    measurementId: _env('FB_MEASUREMENT_ID'),
  );

  /// (Opcional) Valida en runtime que todo llegó.
  static void validateOrThrow() {
    final o = web;
    String miss(String name) => 'Falta $name (dart-define) en build/deploy';
    if (o.apiKey.isEmpty) throw StateError(miss('FB_API_KEY'));
    if (o.appId.isEmpty) throw StateError(miss('FB_APP_ID'));
    if (o.projectId.isEmpty) throw StateError(miss('FB_PROJECT_ID'));
    if (o.messagingSenderId.isEmpty) {
      throw StateError(miss('FB_MESSAGING_SENDER_ID'));
    }
    if (o.authDomain.isEmpty) throw StateError(miss('FB_AUTH_DOMAIN'));
    if (o.storageBucket.isEmpty) throw StateError(miss('FB_STORAGE_BUCKET'));
    // measurementId puede venir vacío si no usas Analytics, pero lo dejamos igual:
    // if (o.measurementId?.isEmpty ?? true) throw StateError(miss('FB_MEASUREMENT_ID'));
  }
}
