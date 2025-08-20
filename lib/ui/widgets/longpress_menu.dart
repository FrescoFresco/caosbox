import 'package:flutter/material.dart';
import '../../models/item.dart';

typedef MenuAction = void Function();

Future<void> showLongpressMenu(BuildContext context, Item it, {
  required MenuAction onOpen,
  required MenuAction onEdit,
  required MenuAction onToggleDone,
  required MenuAction onLink,
  required MenuAction onArchive,
  required MenuAction onDelete,
}) async {
  await showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(it.text, maxLines: 1, overflow: TextOverflow.ellipsis)),
            const Divider(height: 1),
            ListTile(leading: const Icon(Icons.open_in_new), title: const Text('Abrir ficha'), onTap: () { Navigator.pop(ctx); onOpen(); }),
            ListTile(leading: const Icon(Icons.edit), title: const Text('Editar'), onTap: () { Navigator.pop(ctx); onEdit(); }),
            ListTile(leading: const Icon(Icons.check_circle), title: Text(it.status == ItemStatus.completed ? 'Marcar como normal' : 'Marcar como hecho'), onTap: () { Navigator.pop(ctx); onToggleDone(); }),
            ListTile(leading: const Icon(Icons.link), title: const Text('Vincular…'), onTap: () { Navigator.pop(ctx); onLink(); }),
            ListTile(leading: const Icon(Icons.archive), title: Text(it.status == ItemStatus.archived ? 'Desarchivar' : 'Archivar'), onTap: () { Navigator.pop(ctx); onArchive(); }),
            ListTile(leading: const Icon(Icons.delete), title: const Text('Eliminar'), onTap: () { Navigator.pop(ctx); onDelete(); }),
          ],
        ),
      );
    },
  );
}
