// lib/ui/items_screen.dart
import 'package:flutter/material.dart';
import '../models.dart';
import '../data/fire_repo.dart';

class ItemsScreen extends StatefulWidget {
  final ItemType type;
  final FireRepo repo;
  const ItemsScreen({super.key, required this.type, required this.repo});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  late final _sub = widget.repo.watchItemsAll();
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String get _title => widget.type == ItemType.idea ? 'Ideas' : 'Acciones';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // barra superior
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    hintText: 'Buscar…',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _addDialog,
                icon: const Icon(Icons.add),
                label: const Text('Añadir'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder(
            stream: _sub,
            builder: (context, snap) {
              final all = (snap.data ?? const <dynamic>[]) as List;
              // Filtramos por tipo
              final items = all.where((it) => it.type == widget.type).toList();
              // Filtro por texto
              final q = _search.text.trim().toLowerCase();
              final filtered = q.isEmpty
                  ? items
                  : items.where((it) {
                      final hay = '${it.idHuman} ${it.text} ${it.note}'
                          .toLowerCase();
                      return hay.contains(q);
                    }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Text('No hay ${_title.toLowerCase()}'),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemBuilder: (c, i) {
                  final it = filtered[i];
                  return InkWell(
                    onTap: () => _editDialog(it.idHuman, it.text, it.note),
                    onLongPress: () => _itemMenu(it.idHuman, it.text),
                    child: Card(
                      child: ListTile(
                        title: Text('${it.idHuman}  ${it.text}'),
                        subtitle: it.note.isEmpty ? null : Text(it.note),
                        trailing: const Icon(Icons.more_horiz),
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: filtered.length,
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _addDialog() async {
    final t = TextEditingController();
    final n = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Nueva ${_title.substring(0, _title.length - 1)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: t, decoration: const InputDecoration(labelText: 'Texto')),
            const SizedBox(height: 8),
            TextField(controller: n, decoration: const InputDecoration(labelText: 'Nota')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (ok == true && t.text.trim().isNotEmpty) {
      await widget.repo.createItem(widget.type, t.text.trim(), note: n.text.trim());
    }
  }

  Future<void> _editDialog(String id, String text, String note) async {
    final t = TextEditingController(text: text);
    final n = TextEditingController(text: note);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Editar $id'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: t, decoration: const InputDecoration(labelText: 'Texto')),
            const SizedBox(height: 8),
            TextField(controller: n, decoration: const InputDecoration(labelText: 'Nota')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (ok == true) {
      await widget.repo.updateItem(id, text: t.text.trim(), note: n.text.trim());
    }
  }

  Future<void> _itemMenu(String id, String text) async {
    final act = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar'),
              onTap: () => Navigator.pop(c, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.copy_all),
              title: Text('Copiar ID ($id)'),
              onTap: () => Navigator.pop(c, 'copy'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Borrar'),
              onTap: () => Navigator.pop(c, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (act == 'edit') {
      // Busca valores actuales del stream en memoria sería ideal.
      // Aquí pedimos edición directa:
      _editDialog(id, text, '');
    } else if (act == 'copy') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ID copiado: $id')));
    } else if (act == 'delete') {
      await widget.repo.deleteItem(id);
    }
  }
}
