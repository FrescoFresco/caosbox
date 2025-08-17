import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';

import 'firebase_options.dart';
import 'data/fire_repo.dart';

const String kGoogleClientId =
    String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseWebOptionsFromEnv());
  runApp(const CaosBoxApp());
}

class CaosBoxApp extends StatelessWidget {
  const CaosBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CaosBox • beta',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, snap) {
        final user = snap.data;
        if (user == null) {
          return SignInScreen(
            providers: [
              // ¡SIN const! (evita el error de "non-const constructor")
              GoogleProvider(clientId: kGoogleClientId),
            ],
            headerBuilder: (_, __, ___) => const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(
                child: Text('CaosBox • beta', style: TextStyle(fontSize: 24)),
              ),
            ),
          );
        }
        return ItemsPage(user: user);
      },
    );
  }
}

class ItemsPage extends StatefulWidget {
  final User user;
  const ItemsPage({super.key, required this.user});

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  late final FireRepo repo;

  @override
  void initState() {
    super.initState();
    repo = FireRepo(FirebaseFirestore.instance, widget.user.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CaosBox • beta'),
        actions: [
          IconButton(
            tooltip: 'Salir',
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<List<CaosItem>>(
        stream: repo.watchItems(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? const <CaosItem>[];
          if (items.isEmpty) {
            return const Center(
              child: Text('Aún no hay ítems. Pulsa + para añadir.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final it = items[i];
              return ListTile(
                title: Text(
                  it.text,
                  style: TextStyle(
                    decoration:
                        it.done ? TextDecoration.lineThrough : TextDecoration.none,
                  ),
                ),
                leading: Checkbox(
                  value: it.done,
                  onChanged: (v) => repo.toggleDone(it.id, v ?? false),
                ),
                trailing: IconButton(
                  tooltip: 'Borrar',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => repo.deleteItem(it.id),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDialog,
        icon: const Icon(Icons.add),
        label: const Text('Añadir'),
      ),
    );
  }

  Future<void> _addDialog() async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nuevo ítem'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Escribe algo…'),
          onSubmitted: (_) => Navigator.pop(context, true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (ok == true && c.text.trim().isNotEmpty) {
      await repo.addItem(c.text.trim());
    }
  }
}
