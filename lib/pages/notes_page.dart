// lib/pages/notes_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fauth;

class NotesPage extends StatelessWidget {
  final fauth.User user;
  const NotesPage({super.key, required this.user});

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('users').doc(user.uid).collection('notes');

  Future<void> _addNote(BuildContext context) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva nota'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Escribe tu nota…'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
        ],
      ),
    );

    if (ok == true && controller.text.trim().isNotEmpty) {
      await _col.add({
        'text': controller.text.trim(),
        'done': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _toggle(String id, bool value) => _col.doc(id).update({'done': value});
  Future<void> _delete(String id) => _col.doc(id).delete();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _col.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Aún no hay notas.\nPulsa + para crear la primera.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data();
              final text = data['text'] as String? ?? '';
              final done = data['done'] as bool? ?? false;

              return Dismissible(
                key: ValueKey(d.id),
                background: Container(color: Colors.red.withOpacity(0.15)),
                onDismissed: (_) => _delete(d.id),
                child: CheckboxListTile(
                  value: done,
                  onChanged: (v) => _toggle(d.id, v ?? false),
                  title: Text(
                    text,
                    style: TextStyle(decoration: done ? TextDecoration.lineThrough : null),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNote(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
