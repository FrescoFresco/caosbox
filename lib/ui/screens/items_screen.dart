import 'package:flutter/material.dart';
import 'package:caosbox/models.dart';
import 'package:caosbox/data/fire_repo.dart';
import 'package:caosbox/ui/widgets/simple_search_field.dart';
import 'package:caosbox/ui/widgets/item_tile.dart';

class ItemsScreen extends StatefulWidget {
  final FireRepo repo;
  const ItemsScreen({super.key, required this.repo});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> with AutomaticKeepAliveClientMixin {
  ItemType? _typeFilter;          // null = ambos (Ideas + Acciones)
  String _query = '';

  @override
  bool get wantKeepAlive => true;

  void _add(ItemType t) async {
    await widget.repo.addItem(t);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      children: [
        // Header con chips (Ideas / Acciones) y botón + añadir
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              FilterChip(
                label: const Text('Ideas'),
                selected: _typeFilter == ItemType.idea,
                onSelected: (v) => setState(() => _typeFilter = v ? ItemType.idea : null),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Acciones'),
                selected: _typeFilter == ItemType.action,
                onSelected: (v) => setState(() => _typeFilter = v ? ItemType.action : null),
              ),
              const Spacer(),
              PopupMenuButton<ItemType>(
                tooltip: 'Añadir',
                onSelected: _add,
                itemBuilder: (ctx) => const [
                  PopupMenuItem(value: ItemType.idea, child: Text('Nueva Idea')),
                  PopupMenuItem(value: ItemType.action, child: Text('Nueva Acción')),
                ],
                child: FilledButton.icon(
                  onPressed: null, // se abre el menú
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir'),
                ),
              )
            ],
          ),
        ),

        // Buscador simple
        SimpleSearchField(
          hintText: 'Buscar por id, texto o nota…',
          onChanged: (q) => setState(() => _query = q.trim().toLowerCase()),
        ),

        // Lista
        Expanded(
          child: StreamBuilder<List<Item>>(
            stream: widget.repo.watchItemsAll(), // stream de todos los items
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = (snap.data ?? const <Item>[]);

              // Filtro por tipo (opcional) + búsqueda en cliente
              final filtered = data.where((it) {
                if (_typeFilter != null && it.type != _typeFilter) return false;
                if (_query.isEmpty) return true;
                final text = '${it.idHuman} ${it.text} ${it.note ?? ''}'.toLowerCase();
                return text.contains(_query);
              }).toList();

              if (filtered.isEmpty) {
                return const Center(child: Text('No hay elementos.'));
              }

              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (ctx, i) {
                  final it = filtered[i];
                  final links = widget.repo.linksOf(it.id); // si no lo tienes, pon 0 o calcula fuera
                  final linkCount = links?.length ?? 0;

                  return ItemTile(
                    item: it,
                    linkCount: linkCount,
                    onToggleDone: () => widget.repo.toggleStatus(it.id, done: !it.done),
                    onDelete: () => widget.repo.deleteItem(it.id),
                    onTap: () async {
                      await _editBottomSheet(context, it);
                    },
                    onLongPress: () async {
                      await _quickActions(context, it);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _editBottomSheet(BuildContext context, Item it) async {
    final textC = TextEditingController(text: it.text);
    final noteC = TextEditingController(text: it.note ?? '');
    final focus = FocusNode();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: ListView(
            padding: const EdgeInsets.all(16),
            shrinkWrap: true,
            children: [
              Text('${it.idHuman}', style: Theme.of(ctx).textTheme.labelSmall),
              const SizedBox(height: 8),
              TextField(
                controller: textC,
                focusNode: focus,
                autofocus: true,
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: 'Texto',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteC,
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: 'Nota',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton(
                    onPressed: () async {
                      await widget.repo.updateText(it.id, textC.text.trim());
                      await widget.repo.updateNote(it.id, noteC.text.trim().isEmpty ? null : noteC.text.trim());
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Guardar'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    focus.dispose();
    textC.dispose();
    noteC.dispose();
  }

  Future<void> _quickActions(BuildContext context, Item it) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.check),
                title: Text(it.done ? 'Marcar pendiente' : 'Marcar completado'),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.repo.toggleStatus(it.id, done: !it.done);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Eliminar'),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.repo.deleteItem(it.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
