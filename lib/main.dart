// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fauth;

import 'auth_gate.dart';

FirebaseOptions _webOptionsFromEnv() {
  // ⚠️ Las claves deben ser literales aquí (nada de helper functions)
  return FirebaseOptions(
    apiKey: const String.fromEnvironment('FB_API_KEY', defaultValue: ''),
    appId: const String.fromEnvironment('FB_APP_ID', defaultValue: ''),
    projectId: const String.fromEnvironment('FB_PROJECT_ID', defaultValue: ''),
    messagingSenderId:
        const String.fromEnvironment('FB_MESSAGING_SENDER_ID', defaultValue: ''),
    authDomain: const String.fromEnvironment('FB_AUTH_DOMAIN', defaultValue: ''),
    storageBucket:
        const String.fromEnvironment('FB_STORAGE_BUCKET', defaultValue: ''),
    measurementId:
        const String.fromEnvironment('FB_MEASUREMENT_ID', defaultValue: ''),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: _webOptionsFromEnv());
  runApp(const _Root());
}

class _Root extends StatelessWidget {
  const _Root({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CaosBox',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: AuthGate(
        builder: (context, fauth.User user) {
          // Cambia por tu widget principal si quieres (ej. CaosApp(user: user))
          return HomeScreen(user: user);
        },
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final fauth.User user;
  const HomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user.displayName ?? user.email ?? user.uid;
    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, $name'),
        actions: [
          IconButton(
            tooltip: 'Salir',
            onPressed: () => fauth.FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: const Center(
        child: Text('¡Autenticado! Aquí va tu app.'),
      ),
    );
  }
}
