import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';

import 'firebase_options.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configurar proveedor Google para FirebaseUI (NO uses const aquí)
  FirebaseUIAuth.configureProviders([
    GoogleProvider(
      clientId: const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: ''),
    ),
  ]);

  runApp(const CaosApp());
}
