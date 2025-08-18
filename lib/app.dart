import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'data/fire_repo.dart';
import 'models/item.dart';
import 'ui/screens/tab_items.dart';
import 'ui/screens/tab_links.dart';

class CaosApp extends StatefulWidget {
  const CaosApp({super.key});

  @override
  State<CaosApp> createState() => _CaosAppState();
}

class _CaosAppState extends State<CaosApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CaosBox • beta',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const _AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          // Pantalla muy simple de login (FirebaseUI se configura desde main.dart)
          return const _SimpleLogin();
        }
        final user = snap.data!;
        final repo = FireRepo(FirebaseFirestore.instance, user.uid);
        return _Home(repo: repo, user: user);
      },
    );
  }
}

class _SimpleLogin extends StatelessWidget {
  const _SimpleLogin();

  @override
  Widget build(BuildContext context) {
    // Mantenemos esto minimal; el SignInScreen real se muestra en main.dart con FirebaseUI
    // Si prefieres, aquí podrías navegar a ese SignInScreen.
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('Inicia sesión con Google para continuar'),
            SizedBox(height: 12),
            Text('Pulsa “Continuar con Google” en la pantalla de inicio'),
          ],
        ),
      ),
    );
  }
}

class _Home extends StatefulWidget {
  final FireRepo repo;
  final User user;
  const _Home({required this.repo, required this.user});

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> with SingleTickerProviderStateMixin {
  late final TabController _tc = TabController(length: 3, vsync: this);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CaosBox • beta'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
        bottom: TabBar(
          controller: _tc,
          tabs: const [
            Tab(icon: Icon(Icons.lightbulb), text: 'B1'),
            Tab(icon: Icon(Icons.assignment), text: 'B2'),
            Tab(icon: Icon(Icons.link), text: 'Enlaces'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tc,
        children: [
          TabItems(repo: widget.repo, type: ItemType.idea),
          TabItems(repo: widget.repo, type: ItemType.action),
          TabLinks(repo: widget.repo),
        ],
      ),
    );
  }
}
