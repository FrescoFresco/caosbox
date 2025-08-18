import 'package:firebase_core/firebase_core.dart';

/// Lee las opciones desde --dart-define en el build (GitHub Actions).
/// NO uses const aquí; el valor viene en tiempo de compilación.
class DefaultFirebaseOptions {
  static String _env(String k, {String def = ''}) =>
      const String.fromEnvironment(k, defaultValue: '');

  static FirebaseOptions get currentPlatform => FirebaseOptions(
        apiKey: _env('FB_API_KEY'),
        appId: _env('FB_APP_ID'),
        projectId: _env('FB_PROJECT_ID'),
        messagingSenderId: _env('FB_MESSAGING_SENDER_ID'),
        authDomain: _env('FB_AUTH_DOMAIN'),
        storageBucket: _env('FB_STORAGE_BUCKET'),
        measurementId: _env('FB_MEASUREMENT_ID'),
      );
}
