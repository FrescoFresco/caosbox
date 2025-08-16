import 'package:firebase_core/firebase_core.dart';

/// Lee --dart-define en build time. OJO: deben ser literales.
class _Env {
  // Requeridos
  static const String apiKey   = String.fromEnvironment('FB_API_KEY');
  static const String appId    = String.fromEnvironment('FB_APP_ID');
  static const String projectId= String.fromEnvironment('FB_PROJECT_ID');
  static const String senderId = String.fromEnvironment('FB_MESSAGING_SENDER_ID');

  // Opcionales (permitimos vacío con defaultValue)
  static const String authDomain   = String.fromEnvironment('FB_AUTH_DOMAIN', defaultValue: '');
  static const String storageBucket= String.fromEnvironment('FB_STORAGE_BUCKET', defaultValue: '');
  static const String measurementId= String.fromEnvironment('FB_MEASUREMENT_ID', defaultValue: '');

  // Google Sign-In (opcional)
  static const String googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '');
}

/// Devuelve FirebaseOptions para Web usando los --dart-define
FirebaseOptions firebaseWebOptions() {
  // Validación de mínimos requeridos
  if (_Env.apiKey.isEmpty)    { throw StateError('Falta dart-define FB_API_KEY'); }
  if (_Env.appId.isEmpty)     { throw StateError('Falta dart-define FB_APP_ID'); }
  if (_Env.projectId.isEmpty) { throw StateError('Falta dart-define FB_PROJECT_ID'); }
  if (_Env.senderId.isEmpty)  { throw StateError('Falta dart-define FB_MESSAGING_SENDER_ID'); }

  // Opcionales: convertimos '' -> null
  final String? authDomain    = _Env.authDomain.isEmpty    ? null : _Env.authDomain;
  final String? storageBucket = _Env.storageBucket.isEmpty ? null : _Env.storageBucket;
  final String? measurementId = _Env.measurementId.isEmpty ? null : _Env.measurementId;

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
