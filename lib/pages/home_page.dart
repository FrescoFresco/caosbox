// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fauth;

class HomePage extends StatelessWidget {
  final fauth.User user;
  const HomePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user.displayName ?? user.email ?? 'Usuario';
    return Center(
      child: Text(
        'Hola, $name 👋\n\n¡Autenticado! Aquí va tu app.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
