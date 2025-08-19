// lib/ui/widgets/item_card.dart
import 'package:flutter/material.dart';
import '../../models/item.dart';
import '../../models/enums.dart';

class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    required this.item,
    required this.onStatus,
    required this.onNote,
    required this.onDelete,
  });

  final Item item;
  final Future<void> Function(ItemStatus s) onStatus;
  final Future<void> Function(String note) onNote;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final muted = item.status != ItemStatus.normal;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.text,
                style: TextStyle(
                  fontSize: 16,
                  decoration: item.status == ItemStatus.completed ? TextDecoration.lineThrough : null,
                  color: muted ? Colors.grey[700] : null,
                )),
            if (item.note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(item.note, style: TextStyle(color: Colors.grey[600])),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => onStatus(
                    item.status == ItemStatus.completed ? ItemStatus.normal : ItemStatus.completed,
                  ),
                  child: Text(item.status == ItemStatus.completed ? 'Marcar: normal' : 'Marcar: completado'),
                ),
                OutlinedButton(
                  onPressed: () => onStatus(
                    item.status == ItemStatus.archived ? ItemStatus.normal : ItemStatus.archived,
                  ),
                  child: Text(item.status == ItemStatus.archived ? 'Desarchivar' : 'Archivar'),
                ),
                TextButton(
                  onPressed: () async {
                    final c = TextEditingController(text: item.note);
                    final res = await showDialog<String>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Nota'),
                        content: TextField(
                          controller: c,
                          decoration: const InputDecoration(hintText: 'Escribe una nota…'),
                          minLines: 1,
                          maxLines: 5,
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                          FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Guardar')),
                        ],
                      ),
                    );
                    if (res != null) await onNote(res);
                  },
                  child: const Text('Nota'),
                ),
                TextButton(
                  onPressed: onDelete,
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Eliminar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
