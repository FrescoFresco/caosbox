import 'package:flutter/material.dart';
import 'package:caosbox/models.dart';

class ItemTile extends StatelessWidget {
  final Item item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onToggleDone;
  final VoidCallback? onDelete;
  final int linkCount;

  const ItemTile({
    super.key,
    required this.item,
    this.onTap,
    this.onLongPress,
    this.onToggleDone,
    this.onDelete,
    this.linkCount = 0,
  });

  Color _typeColor(ItemType t, BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return switch (t) {
      ItemType.idea => isDark ? Colors.lightBlueAccent : Colors.blue.shade100,
      ItemType.action => isDark ? Colors.orangeAccent : Colors.orange.shade100,
    };
  }

  @override
  Widget build(BuildContext context) {
    final done = item.done;
    final theme = Theme.of(context);

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge tipo (Idea/Acción)
              Container(
                width: 8,
                height: 48,
                margin: const EdgeInsets.only(right: 12, top: 4),
                decoration: BoxDecoration(
                  color: _typeColor(item.type, context),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),

              // Contenido principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Primera línea: ID, estado, enlaces
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item.idHuman,
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                        if (done)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Completado', style: TextStyle(fontSize: 11)),
                          ),
                        if (linkCount > 0)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.link, size: 14),
                              const SizedBox(width: 4),
                              Text('$linkCount', style: theme.textTheme.labelSmall),
                            ],
                          ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Texto principal
                    Text(
                      item.text.isEmpty ? '— sin texto —' : item.text,
                      style: theme.textTheme.titleSmall?.copyWith(
                        decoration: done ? TextDecoration.lineThrough : null,
                        color: done ? theme.disabledColor : null,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    if ((item.note ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.note!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.75),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Acciones rápidas
              Column(
                children: [
                  IconButton(
                    tooltip: done ? 'Marcar pendiente' : 'Marcar completado',
                    onPressed: onToggleDone,
                    icon: Icon(done ? Icons.check_box : Icons.check_box_outline_blank),
                  ),
                  IconButton(
                    tooltip: 'Eliminar',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
