// lib/ui/widgets/item_tile.dart
import 'package:flutter/material.dart';
import 'package:caosbox/core/models/item.dart';
import 'package:caosbox/core/models/enums.dart';

class ItemTile extends StatelessWidget {
  final Item item;
  final bool compact;
  final VoidCallback? onToggleCompleted;
  final ValueChanged<String>? onEditText;
  final ValueChanged<String>? onEditNote;
  final VoidCallback? onTap;

  const ItemTile({
    super.key,
    required this.item,
    this.compact = false,
    this.onToggleCompleted,
    this.onEditText,
    this.onEditNote,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = compact ? Theme.of(context).textTheme.bodyMedium : Theme.of(context).textTheme.bodyLarge;
    return ListTile(
      onTap: onTap,
      onLongPress: () => _showInfo(context),
      leading: Icon(typeIcon(item.type)),
      title: Text(item.text.isEmpty ? '(sin texto)' : item.text, style: style),
      subtitle: item.note.isEmpty ? null : Text('📝 ${item.note}', maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Wrap(
        spacing: 4,
        children: [
          IconButton(
            tooltip: 'Editar texto',
            onPressed: onEditText == null ? null : () async {
              final t = await _ask(context, 'Editar texto', initial: item.text);
              if ((t ?? '') != '') onEditText!(t!.trim());
            },
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            tooltip: 'Editar nota',
            onPressed: onEditNote == null ? null : () async {
              final t = await _ask(context, 'Editar nota', initial: item.note, multi: true);
              if (t != null) onEditNote!(t);
            },
            icon: const Icon(Icons.note_alt),
          ),
          IconButton(
            tooltip: 'Completado',
            onPressed: onToggleCompleted,
            icon: Icon(item.status == ItemStatus.completed ? Icons.check_circle : Icons.radio_button_unchecked),
          ),
        ],
      ),
    );
  }

  void _showInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Detalle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${item.id}'),
            Text('Tipo: ${item.type.name}'),
            Text('Estado: ${item.status.label}'),
            Text('Creado: ${item.createdAt}'),
            Text('Modificado: ${item.modifiedAt}'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
      ),
    );
  }

  Future<String?> _ask(BuildContext ctx, String title, {String initial = '', bool multi = false}) {
    final c = TextEditingController(text: initial);
    return showDialog<String>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, autofocus: true, minLines: multi ? 3 : 1, maxLines: multi ? 6 : 1),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('Guardar')),
        ],
      ),
    );
  }
}
