import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../data/fire_repo.dart';
import '../data/item.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});
  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  late final FireRepo repo;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser!;
    repo = FireRepo(FirebaseFirestore.instance, user.uid);
  }

  Future<void> _addItemDialog() async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nuevo item'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Escribe tu nota'),
          onSubmitted: (_) => Navigator.pop(context, true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (ok == true && c.text.trim().isNotEmpty) {
      await repo.addItem(c.text.trim());
    }
  }

  Future<void> _editItemDialog(Item item) async {
    final c = TextEditingController(text: item.text);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar item'),
        content: TextField(
          controller: c,
          autofocus: true,
          onSubmitted: (_) => Navigator.pop(context, true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (ok == true && c.text.trim().isNotEmpty) {
      await repo.updateItem(item.id, c.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('CaosBox • Items'),
        actions: [
          Center(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(user.displayName ?? user.email ?? '', style: const TextStyle(fontSize: 12)),
          )),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () async => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<Item>>(
        stream: repo.streamItems(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final items = snap.data ?? const [];
          if (items.isEmpty) {
            return const Center(child: Text('Aún no hay items. Pulsa + para crear uno.'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final it = items[i];
              return Dismissible(
                key: ValueKey(it.id),
                background: Container(color: Colors.redAccent),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => repo.deleteItem(it.id),
                child: ListTile(
                  title: Text(it.text),
                  subtitle: Text('Editado: ${it.modifiedAt.toLocal()}'),
                  onTap: () => _editItemDialog(it),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItemDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
