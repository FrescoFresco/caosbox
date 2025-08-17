import 'package:firebase_core/firebase_core.dart';

String _env(String k, {String def = ''}) =>
    const String.fromEnvironment(k, defaultValue: '');

FirebaseOptions firebaseWebOptionsFromEnv() {
  final apiKey = _env('FB_API_KEY');
  final appId = _env('FB_APP_ID');
  final projectId = _env('FB_PROJECT_ID');
  final senderId = _env('FB_MESSAGING_SENDER_ID');
  final authDomain = _env('FB_AUTH_DOMAIN');
  final bucket = _env('FB_STORAGE_BUCKET');
  final meas = const String.fromEnvironment('FB_MEASUREMENT_ID', defaultValue: '');

  // Validaciones mínimas
  if ([apiKey, appId, projectId, senderId].any((s) => s.isEmpty)) {
    throw 'Faltan dart-defines de Firebase.';
  }

  return FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    projectId: projectId,
    messagingSenderId: senderId,
    authDomain: authDomain.isEmpty ? null : authDomain,
    storageBucket: bucket.isEmpty ? null : bucket,
    measurementId: meas.isEmpty ? null : meas,
  );
}
