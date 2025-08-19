import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (!kIsWeb) {
      throw UnsupportedError('DefaultFirebaseOptions solo está configurado para Web.');
    }

    // 👇 Cada clave como literal (requerido por fromEnvironment)
    const String apiKey              = String.fromEnvironment('FB_API_KEY',              defaultValue: '');
    const String appId               = String.fromEnvironment('FB_APP_ID',               defaultValue: '');
    const String projectId           = String.fromEnvironment('FB_PROJECT_ID',           defaultValue: '');
    const String messagingSenderId   = String.fromEnvironment('FB_MESSAGING_SENDER_ID',  defaultValue: '');
    const String authDomain          = String.fromEnvironment('FB_AUTH_DOMAIN',          defaultValue: '');
    const String storageBucket       = String.fromEnvironment('FB_STORAGE_BUCKET',       defaultValue: '');
    const String measurementId       = String.fromEnvironment('FB_MEASUREMENT_ID',       defaultValue: '');

    // Construimos las opciones (en Web, authDomain / storageBucket / measurementId son opcionales)
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      projectId: projectId,
      messagingSenderId: messagingSenderId.isEmpty ? null : messagingSenderId,
      authDomain: authDomain.isEmpty ? null : authDomain,
      storageBucket: storageBucket.isEmpty ? null : storageBucket,
      measurementId: measurementId.isEmpty ? null : measurementId,
    );
  }
}
