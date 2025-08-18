// lib/app_home.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'ui/items_screen.dart';

class AppHome extends StatelessWidget {
  const AppHome({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Inicia sesión con Google para continuar')),
      );
    }
    return const ItemsScreen();
    // Si quieres tabs (Items/Links/Cuenta), luego lo montamos aquí.
  }
}
