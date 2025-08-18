import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fauth;

import 'firebase_options.dart'; // el que ya tienes generado
import 'auth_gate.dart';
import 'caos_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const CaosBoxApp());
}

class CaosBoxApp extends StatelessWidget {
  const CaosBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CaosBox • beta',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C63FF)),
        useMaterial3: true,
      ),
      // 👇 Si no hay sesión, muestra SignInScreen; si hay, entra a tu app
      home: AuthGate(
        builder: (context, fauth.User user) {
          return CaosApp(user: user);
        },
      ),
    );
  }
}
