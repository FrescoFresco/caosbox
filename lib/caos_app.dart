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
            onPressed: () async {
              await fauth.FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: const Center(
        child: Text('¡Autenticado! Aquí va tu app.'),
      ),
    );
  }
}
