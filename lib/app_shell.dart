// lib/app_shell.dart
import 'package:flutter/material.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('CaosBox'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'B1', icon: Icon(Icons.lightbulb_outline)),
              Tab(text: 'B2', icon: Icon(Icons.checklist)),
              Tab(text: 'Enlaces', icon: Icon(Icons.link)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _Placeholder('Bloque B1 (Ideas)'),
            _Placeholder('Bloque B2 (Acciones)'),
            _Placeholder('Enlaces'),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String text;
  const _Placeholder(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(text, style: Theme.of(context).textTheme.headlineSmall),
    );
  }
}

