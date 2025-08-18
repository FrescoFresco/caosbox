// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  // En web usamos estas opciones
  static FirebaseOptions get currentPlatform => web;

  static final FirebaseOptions web = _fromEnv();

  static FirebaseOptions _fromEnv() {
    // Lee de --dart-define en build
    final apiKey                 = const String.fromEnvironment('FB_API_KEY', defaultValue: '');
    final appId                  = const String.fromEnvironment('FB_APP_ID', defaultValue: '');
    final projectId              = const String.fromEnvironment('FB_PROJECT_ID', defaultValue: '');
    final messagingSenderId      = const String.fromEnvironment('FB_MESSAGING_SENDER_ID', defaultValue: '');
    final authDomain             = const String.fromEnvironment('FB_AUTH_DOMAIN', defaultValue: '');
    final storageBucket          = const String.fromEnvironment('FB_STORAGE_BUCKET', defaultValue: '');
    final measurementId          = const String.fromEnvironment('FB_MEASUREMENT_ID', defaultValue: '');

    // Validaciones (para fallar con mensaje útil si falta algo)
    void requireNonEmpty(String v, String name) {
      if (v.isEmpty) {
        throw StateError('Falta --dart-define=$name en el build.');
      }
    }

    requireNonEmpty(apiKey,            'FB_API_KEY');
    requireNonEmpty(appId,             'FB_APP_ID');
    requireNonEmpty(projectId,         'FB_PROJECT_ID');
    requireNonEmpty(messagingSenderId, 'FB_MESSAGING_SENDER_ID');
    requireNonEmpty(authDomain,        'FB_AUTH_DOMAIN');
    requireNonEmpty(storageBucket,     'FB_STORAGE_BUCKET');
    // measurementId lo dejamos opcional

    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      projectId: projectId,
      messagingSenderId: messagingSenderId,
      authDomain: authDomain,
      storageBucket: storageBucket,
      measurementId: measurementId, // puede ser '' y no rompe
    );
  }
}
