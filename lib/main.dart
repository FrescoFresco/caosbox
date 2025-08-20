// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth_gate.dart';
import 'app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const CaosApp());
}

class CaosApp extends StatelessWidget {
  const CaosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CaosBox',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: AuthGate(
        builder: (user) => const AppShell(), // tu app real tras login
      ),
    );
  }
}
