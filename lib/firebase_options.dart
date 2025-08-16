import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => FirebaseOptions(
        apiKey: _s('FB_API_KEY'),
        appId: _s('FB_APP_ID'),
        projectId: _s('FB_PROJECT_ID'),
        messagingSenderId: _s('FB_MESSAGING_SENDER_ID'),
        authDomain: _s('FB_AUTH_DOMAIN'),
        storageBucket: _s('FB_STORAGE_BUCKET'),
        measurementId: _s('FB_MEASUREMENT_ID'),
      );

  static String _s(String k) {
    final v = String.fromEnvironment(k);
    if (v.isEmpty) {
      throw StateError('Falta --dart-define=$k en el build/deploy');
    }
    return v;
  }
}
