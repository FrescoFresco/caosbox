import 'package:flutter/material.dart';
import 'package:caosbox/models.dart';
import 'package:caosbox/data/fire_repo.dart';
import 'package:caosbox/ui/widgets/simple_search_field.dart';
import 'package:caosbox/ui/widgets/item_tile.dart';

class LinksScreen extends StatefulWidget {
  final FireRepo repo;
  const LinksScreen({super.key, required this.repo});

  @override
  State<LinksScreen> createState() => _LinksScreenState();
}

class _LinksScreenState extends State<LinksScreen> with AutomaticKeepAliveClientMixin {
  String _leftQuery = '';
  String _rightQuery = '';

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final repo = widget.repo;

    return Row(
      children: [
        // Columna izquierda
        Expanded(
          child: Column(
            children: [
              const SizedBox(height: 8),
              const Text('B1', style: TextStyle(fontWeight: FontWeight.w600)),
              SimpleSearchField(
                hintText: 'Buscar B1…',
                onChanged: (q) => setState(() => _leftQuery = q.trim().toLowerCase()),
              ),
              Expanded(
                child: StreamBuilder<List<Item>>(
                  stream: repo.watchItemsAll(),
                  builder: (ctx, snap) {
                    final items = (snap.data ?? const <Item>[])
                        .where((it) => it.type == ItemType.idea)
                        .where((it) {
                          if (_leftQuery.isEmpty) return true;
                          final text = '${it.idHuman} ${it.text} ${it.note ?? ''}'.toLowerCase();
                          return text.contains(_leftQuery);
                        })
                        .toList();

                    if (items.isEmpty) return const Center(child: Text('Vacío'));

                    return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (ctx, i) {
                        final it = items[i];
                        final linkCount = repo.linkedTo(it.id).length; // si no lo tienes, pon 0
                        return ItemTile(
                          item: it,
                          linkCount: linkCount,
                          onTap: () => _pickLeft(ctx, it),
                          onToggleDone: () => repo.toggleStatus(it.id, done: !it.done),
                          onDelete: () => repo.deleteItem(it.id),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Separador
        const VerticalDivider(width: 1),

        // Columna derecha
        Expanded(
          child: Column(
            children: [
              const SizedBox(height: 8),
              const Text('B2', style: TextStyle(fontWeight: FontWeight.w600)),
              SimpleSearchField(
                hintText: 'Buscar B2…',
                onChanged: (q) => setState(() => _rightQuery = q.trim().toLowerCase()),
              ),
              Expanded(
                child: StreamBuilder<List<Item>>(
                  stream: repo.watchItemsAll(),
                  builder: (ctx, snap) {
                    final items = (snap.data ?? const <Item>[])
                        .where((it) => it.type == ItemType.action)
                        .where((it) {
                          if (_rightQuery.isEmpty) return true;
                          final text = '${it.idHuman} ${it.text} ${it.note ?? ''}'.toLowerCase();
                          return text.contains(_rightQuery);
                        })
                        .toList();

                    if (items.isEmpty) return const Center(child: Text('Vacío'));

                    return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (ctx, i) {
                        final it = items[i];
                        final linkCount = repo.linkedTo(it.id).length; // si no lo tienes, pon 0
                        return ItemTile(
                          item: it,
                          linkCount: linkCount,
                          onTap: () => _pickRight(ctx, it),
                          onToggleDone: () => repo.toggleStatus(it.id, done: !it.done),
                          onDelete: () => repo.deleteItem(it.id),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Item? _leftSel;
  Item? _rightSel;

  Future<void> _pickLeft(BuildContext context, Item it) async {
    setState(() => _leftSel = it);
    await _tryLink(context);
  }

  Future<void> _pickRight(BuildContext context, Item it) async {
    setState(() => _rightSel = it);
    await _tryLink(context);
  }

  Future<void> _tryLink(BuildContext context) async {
    if (_leftSel == null || _rightSel == null) return;
    final a = _leftSel!;
    final b = _rightSel!;
    _leftSel = null;
    _rightSel = null;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Crear enlace'),
        content: Text('¿Enlazar ${a.idHuman} ↔ ${b.idHuman}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enlazar')),
        ],
      ),
    );

    if (ok == true) {
      await widget.repo.upsertLink(a.id, b.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enlace creado')),
        );
      }
    }
  }
}
