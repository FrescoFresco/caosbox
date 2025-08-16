import 'package:firebase_core/firebase_core.dart';

/// Lee --dart-define en build time (retorna '' si no está definido)
class _Env {
  static String _s(String k) => const String.fromEnvironment(k);

  // Requeridos
  static String get apiKey => _s('FB_API_KEY');
  static String get appId => _s('FB_APP_ID');
  static String get projectId => _s('FB_PROJECT_ID');
  static String get senderId => _s('FB_MESSAGING_SENDER_ID');

  // Opcionales (pueden venir vacíos)
  static String get authDomain => _s('FB_AUTH_DOMAIN');
  static String get storageBucket => _s('FB_STORAGE_BUCKET');
  static String get measurementId => _s('FB_MEASUREMENT_ID');

  // Para Google Sign-In Web (lo usas en tu UI si hace falta)
  static String get googleWebClientId => _s('GOOGLE_WEB_CLIENT_ID');
}

/// Devuelve FirebaseOptions para Web a partir de los --dart-define.
/// Valida los mínimos requeridos y permite opcionales vacíos.
FirebaseOptions firebaseWebOptions() {
  final req = <String, String>{
    'FB_API_KEY': _Env.apiKey,
    'FB_APP_ID': _Env.appId,
    'FB_PROJECT_ID': _Env.projectId,
    'FB_MESSAGING_SENDER_ID': _Env.senderId,
  };

  for (final e in req.entries) {
    if (e.value.isEmpty) {
      throw StateError('Falta dart-define ${e.key}');
    }
  }

  final String? authDomain =
      _Env.authDomain.isEmpty ? null : _Env.authDomain;
  final String? storageBucket =
      _Env.storageBucket.isEmpty ? null : _Env.storageBucket;
  final String? measurementId =
      _Env.measurementId.isEmpty ? null : _Env.measurementId;

  return FirebaseOptions(
    apiKey: _Env.apiKey,
    appId: _Env.appId,
    projectId: _Env.projectId,
    messagingSenderId: _Env.senderId,
    authDomain: authDomain,
    storageBucket: storageBucket,
    measurementId: measurementId,
  );
}
