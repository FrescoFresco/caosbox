// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (!kIsWeb) {
      // Tu app es web; si algún día compilas móvil, crea opciones nativas.
      throw UnsupportedError('Solo configurado para Web.');
    }
    String env(String k) => const String.fromEnvironment(k);

    return FirebaseOptions(
      apiKey: env('FB_API_KEY'),
      appId: env('FB_APP_ID'),
      projectId: env('FB_PROJECT_ID'),
      messagingSenderId: env('FB_MESSAGING_SENDER_ID'),
      authDomain: env('FB_AUTH_DOMAIN'),
      storageBucket: env('FB_STORAGE_BUCKET'),
      measurementId: env('FB_MEASUREMENT_ID'),
    );
  }
}
