import 'package:flutter/material.dart';
import '../../models/item.dart';

class BlockTile extends StatelessWidget {
  final Item it;
  final VoidCallback onOpen;
  final VoidCallback onLong;
  final VoidCallback onToggleStatus;
  const BlockTile({super.key, required this.it, required this.onOpen, required this.onLong, required this.onToggleStatus});

  IconData get _icon {
    switch (it.status) {
      case ItemStatus.completed:
        return Icons.check_circle;
      case ItemStatus.archived:
        return Icons.archive;
      case ItemStatus.normal:
      default:
        return Icons.radio_button_unchecked;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: IconButton(icon: Icon(_icon), onPressed: onToggleStatus),
      title: Text(it.text, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: it.note.isEmpty ? null : Text(it.note, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: onOpen,
      onLongPress: onLong,
      trailing: const Icon(Icons.more_vert),
    );
  }
}
