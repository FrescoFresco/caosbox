// lib/caos_app.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fauth;

import 'pages/home_page.dart';
import 'pages/notes_page.dart';

class CaosApp extends StatefulWidget {
  final fauth.User user;
  const CaosApp({super.key, required this.user});

  @override
  State<CaosApp> createState() => _CaosAppState();
}

class _CaosAppState extends State<CaosApp> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(user: widget.user),
      NotesPage(user: widget.user),
    ];

    final titles = [
      'Inicio',
      'Notas',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('CaosBox • ${widget.user.displayName ?? widget.user.email ?? "Usuario"}'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => fauth.FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.note_outlined), selectedIcon: Icon(Icons.note), label: 'Notas'),
        ],
      ),
    );
  }
}
