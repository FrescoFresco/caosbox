import 'package:flutter/material.dart';
import '../../models/item.dart';

class ItemTile extends StatelessWidget {
  final Item it;
  final bool selectable;
  final bool selected;
  final VoidCallback? onToggleStatus;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;

  const ItemTile({
    super.key,
    required this.it,
    this.selectable = false,
    this.selected = false,
    this.onToggleStatus,
    this.onTap,
    this.onLongPress,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = it.status == ItemStatus.completed;
    return Card(
      elevation: 0.5,
      child: ListTile(
        leading: selectable
            ? Checkbox(value: selected, onChanged: (_) => onTap?.call())
            : Icon(it.type.icon),
        title: Text(
          it.text.isEmpty ? '(sin texto)' : it.text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: isDone
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
        subtitle: it.note.isEmpty
            ? null
            : Text(
                it.note,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        trailing: trailing ??
            IconButton(
              tooltip: isDone ? 'Marcar como normal' : 'Marcar como completado',
              icon: Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked),
              onPressed: onToggleStatus,
            ),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
