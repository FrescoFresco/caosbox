// lib/ui/screens/items_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/core/models/enums.dart';
import 'package:caosbox/ui/widgets/advanced_search.dart';
import 'package:caosbox/ui/widgets/item_tile.dart';

class ItemsScreen extends StatefulWidget {
  final ItemType type;
  const ItemsScreen({super.key, required this.type});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final all = st.byType(widget.type);
    final filtered = all.where((e) {
      if (_q.trim().isEmpty) return true;
      final t = _q.toLowerCase();
      return e.id.toLowerCase().contains(t) || e.text.toLowerCase().contains(t) || e.note.toLowerCase().contains(t);
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          AdvancedSearchBar(
            hint: 'Buscar por id/texto/notas…',
            onSimpleQueryChanged: (v) => setState(() => _q = v),
            onApplyAdvanced: (spec) {
              // (Básico) por ahora usamos solo el campo "query" de spec
              setState(() => _q = spec.query);
            },
            onExportQueryJson: (_) {}, // luego lo conectamos si quieres
            onImportQueryJson: (_) {}, // idem
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) => ItemTile(
                item: filtered[i],
                onToggleCompleted: () => st.toggleCompleted(filtered[i].id),
                onEditText: (txt) => st.updateText(filtered[i].id, txt),
                onEditNote: (nt) => st.setNote(filtered[i].id, nt),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(widget.type == ItemType.idea ? 'Añadir idea' : 'Añadir acción'),
        onPressed: () async {
          final txt = await _askText(context, 'Nuevo ${widget.type == ItemType.idea ? 'idea' : 'acción'}');
          if ((txt ?? '').trim().isEmpty) return;
          await st.addItem(widget.type, txt!.trim());
        },
      ),
    );
  }

  Future<String?> _askText(BuildContext ctx, String title) async {
    final c = TextEditingController();
    return showDialog<String>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('Guardar')),
        ],
      ),
    );
  }
}
