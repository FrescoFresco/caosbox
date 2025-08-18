// lib/app.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'data/fire_repo.dart';
import 'models.dart';
import 'ui/items_screen.dart';
import 'ui/links_screen.dart';

class CaosApp extends StatefulWidget {
  final User user;
  const CaosApp({super.key, required this.user});

  @override
  State<CaosApp> createState() => _CaosAppState();
}

class _CaosAppState extends State<CaosApp> {
  late final repo = FireRepo(FirebaseFirestore.instance, widget.user.uid);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('CaosBox'),
          actions: [
            IconButton(
              tooltip: 'Salir',
              onPressed: () => FirebaseAuth.instance.signOut(),
              icon: const Icon(Icons.logout),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Ideas'),
              Tab(text: 'Acciones'),
              Tab(text: 'Enlaces'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ItemsScreen(type: ItemType.idea, repo: repo),
            ItemsScreen(type: ItemType.action, repo: repo),
            LinksScreen(repo: repo),
          ],
        ),
      ),
    );
  }
}
