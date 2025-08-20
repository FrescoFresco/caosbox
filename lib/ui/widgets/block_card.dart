import 'package:flutter/material.dart';
import '../../models/item.dart';

class BlockCard extends StatelessWidget {
  final Item it;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onToggleStatus;
  final int? linkCount;

  const BlockCard({
    super.key,
    required this.it,
    required this.onTap,
    required this.onLongPress,
    required this.onToggleStatus,
    this.linkCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = it.status == ItemStatus.completed;
    final isArchived = it.status == ItemStatus.archived;
    final accent = it.type == ItemType.b1 ? Colors.indigo : Colors.teal;

    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      decoration: (isDone || isArchived) ? TextDecoration.lineThrough : null,
    );

    return Opacity(
      opacity: isArchived ? 0.6 : 1,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16), bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                onTap: onTap,
                onLongPress: onLongPress,
                leading: Checkbox(value: isDone, onChanged: (_) => onToggleStatus()),
                title: Text(it.text, maxLines: 2, overflow: TextOverflow.ellipsis, style: titleStyle),
                subtitle: it.note.isEmpty ? null : Text(it.note, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (linkCount != null) ...[
                      const Icon(Icons.link, size: 18), const SizedBox(width: 4),
                      Text('${linkCount!}'), const SizedBox(width: 8),
                    ],
                    IconButton(icon: const Icon(Icons.more_vert), onPressed: onLongPress),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
