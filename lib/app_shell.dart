// lib/app_shell.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'data/fire_repo.dart';
import 'ui/screens/ideas_screen.dart';
import 'ui/screens/actions_screen.dart';
import 'ui/screens/links_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.uid});
  final String uid;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final FireRepo _repo;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _repo = FireRepo(FirebaseFirestore.instance, widget.uid);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CaosBox'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'B1 · Ideas'),
            Tab(text: 'B2 · Acciones'),
            Tab(text: 'Enlaces'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: TabBarView(
          controller: _tabs,
          children: [
            IdeasScreen(repo: _repo),
            ActionsScreen(repo: _repo),
            LinksScreen(repo: _repo),
          ],
        ),
      ),
    );
  }
}
