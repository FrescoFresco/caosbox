import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (!kIsWeb) {
      throw UnsupportedError('Sólo Web en este proyecto.');
    }

    final opts = FirebaseOptions(
      apiKey: const String.fromEnvironment('FB_API_KEY'),
      appId: const String.fromEnvironment('FB_APP_ID'),
      projectId: const String.fromEnvironment('FB_PROJECT_ID'),
      messagingSenderId: const String.fromEnvironment('FB_MESSAGING_SENDER_ID'),
      authDomain: const String.fromEnvironment('FB_AUTH_DOMAIN'),
      storageBucket: const String.fromEnvironment('FB_STORAGE_BUCKET'),
    );

    final missing = <String>[];
    void chk(String v, String n) { if (v.isEmpty) missing.add(n); }
    chk(opts.apiKey, 'FB_API_KEY');
    chk(opts.appId, 'FB_APP_ID');
    chk(opts.projectId, 'FB_PROJECT_ID');
    chk(opts.messagingSenderId, 'FB_MESSAGING_SENDER_ID');
    chk(opts.authDomain, 'FB_AUTH_DOMAIN');
    chk(opts.storageBucket, 'FB_STORAGE_BUCKET');
    if (missing.isNotEmpty) {
      throw UnsupportedError('Faltan dart-defines: ${missing.join(', ')}');
    }
    return opts;
  }
}
