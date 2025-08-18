// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fauth;

import 'auth_gate.dart';

// Toma las credenciales desde --dart-define en el build/deploy
FirebaseOptions _webOptionsFromEnv() {
  String env(String k) => const String.fromEnvironment(k, defaultValue: '');
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
      // ⬇️ AQUI usamos AuthGate **con** builder (requerido)
      home: AuthGate(
        builder: (context, fauth.User user) {
          // Si ya tienes tu widget principal (por ejemplo CaosApp),
          // puedes reemplazar HomeScreen por CaosApp(user: user).
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
