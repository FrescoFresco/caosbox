// lib/caos_app.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fauth;

class CaosApp extends StatelessWidget {
  final fauth.User user;
  const CaosApp({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user.displayName ?? user.email ?? 'Usuario';
    return Scaffold(
      appBar: AppBar(
        title: Text('CaosBox • $name'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () async => fauth.FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: const Center(child: Text('¡Autenticado! Aquí va tu app.')),
    );
  }
}
