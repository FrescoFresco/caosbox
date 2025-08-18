import 'package:flutter/material.dart';
import '../../data/fire_repo.dart';
import '../../models/item.dart';
import '../widgets/item_tile.dart';
import '../widgets/simple_search_field.dart';

class TabItems extends StatefulWidget {
  final FireRepo repo;
  final ItemType type;
  const TabItems({super.key, required this.repo, required this.type});

  @override
  State<TabItems> createState() => _TabItemsState();
}

class _TabItemsState extends State<TabItems> {
  String q = '';

  Future<void> _add() async {
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) {
        String t = '';
        return AlertDialog(
          title: Text('Añadir ${widget.type.label}'),
          content: TextField(
            autofocus: true,
            onChanged: (v) => t = v,
            decoration: const InputDecoration(hintText: 'Escribe…'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, t.trim()), child: const Text('Guardar')),
          ],
        );
      },
    );
    if (text != null && text.isNotEmpty) {
      await widget.repo.addItem(widget.type, text);
    }
  }

  Future<void> _edit(Item it) async {
    String t = it.text;
    String n = it.note;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: TextEditingController(text: t),
              onChanged: (v) => t = v,
              decoration: const InputDecoration(labelText: 'Texto'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: TextEditingController(text: n),
              onChanged: (v) => n = v,
              decoration: const InputDecoration(labelText: 'Nota'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (ok == true) {
      if (t != it.text) await widget.repo.updateText(it.id, t);
      if (n != it.note) await widget.repo.updateNote(it.id, n);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: SimpleSearchField(
                  value: q,
                  onChanged: (v) => setState(() => q = v),
                  hint: 'Buscar en ${widget.type.label}…',
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _add,
                icon: const Icon(Icons.add),
                tooltip: 'Añadir',
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Item>>(
            stream: widget.repo.watchByType(widget.type),
            builder: (ctx, snap) {
              if (snap.hasError) {
                return Center(child: Text('Error: ${snap.error}'));
              }
              final data = (snap.data ?? [])
                  .where((e) =>
                      q.isEmpty ||
                      e.id.toLowerCase().contains(q.toLowerCase()) ||
                      e.text.toLowerCase().contains(q.toLowerCase()) ||
                      e.note.toLowerCase().contains(q.toLowerCase()))
                  .toList();
              if (data.isEmpty) {
                return const Center(child: Text('Sin elementos. Usa “+” para añadir.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: data.length,
                itemBuilder: (ctx, i) {
                  final it = data[i];
                  return ItemTile(
                    it: it,
                    onToggleStatus: () {
                      final next = it.status == ItemStatus.completed
                          ? ItemStatus.normal
                          : ItemStatus.completed;
                      widget.repo.setStatus(it.id, next);
                    },
                    onLongPress: () => _edit(it),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
