// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart';

/// Carga las credenciales desde --dart-define.
/// Si falta una requerida, lanzamos un error claro de configuración.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => web;

  // Web (GitHub Pages / Firebase Hosting)
  static final FirebaseOptions web = (() {
    String env(String key, {String def = ''}) =>
        String.fromEnvironment(key, defaultValue: def);

    String req(String key) {
      final v = env(key);
      if (v.isEmpty) {
        throw StateError('Missing --dart-define=$key');
      }
      return v;
    }

    final authDomain = env('FB_AUTH_DOMAIN');
    final storageBucket = env('FB_STORAGE_BUCKET');
    final measurementId = env('FB_MEASUREMENT_ID');

    return FirebaseOptions(
      apiKey: req('FB_API_KEY'),
      appId: req('FB_APP_ID'),
      projectId: req('FB_PROJECT_ID'),
      messagingSenderId: req('FB_MESSAGING_SENDER_ID'),
      // Opcionales en web:
      authDomain: authDomain.isEmpty ? null : authDomain,
      storageBucket: storageBucket.isEmpty ? null : storageBucket,
      measurementId: measurementId.isEmpty ? null : measurementId,
    );
  })();
}
