import 'package:flutter/material.dart';
import '../../models/item.dart';
import '../../models/enums.dart';
import '../../state/app_state.dart';

class ItemTile extends StatelessWidget {
  final Item item;
  final AppState st;

  // interacción
  final VoidCallback? onTap;      // tocar texto (expandir/colapsar)
  final VoidCallback? onInfo;     // long-press → info

  // visual
  final bool expanded;            // muestra 1 línea o todo
  final bool showLinkBadge;       // icono 🔗 si tiene relaciones

  // swipe
  final bool swipeable;           // ✓ / 📁 con deslizamiento

  // checkbox reutilizable (para Enlaces y Relacionado)
  final bool checkbox;            // mostrar checkbox
  final bool checkboxLeading;     // true: a la izquierda, false: a la derecha
  final bool checked;             // estado del checkbox
  final ValueChanged<bool>? onChecked;

  const ItemTile({
    super.key,
    required this.item,
    required this.st,
    this.onTap,
    this.onInfo,
    this.expanded = false,
    this.showLinkBadge = true,
    this.swipeable = true,
    this.checkbox = false,
    this.checkboxLeading = true,
    this.checked = false,
    this.onChecked,
  });

  @override
  Widget build(BuildContext context) {
    final hasLinks = st.links(item.id).isNotEmpty;

    IconData? statusIco;
    Color?   statusCol;
    switch (item.status) {
      case ItemStatus.completed: statusIco = Icons.check;   statusCol = Colors.green; break;
      case ItemStatus.archived:  statusIco = Icons.archive; statusCol = Colors.grey;  break;
      default: break;
    }

    Widget mkCheckbox() => Checkbox(
      value: checked,
      onChanged: onChecked == null ? null : (v) => onChecked!(v ?? false),
    );

    final tile = Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        onTap: onTap,
        onLongPress: onInfo,
        dense: false,
        contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        leading: checkbox && checkboxLeading ? mkCheckbox() : null,
        trailing: checkbox && !checkboxLeading ? mkCheckbox() : null,
        title: Text(
          item.text,
          maxLines: expanded ? null : 1,
          overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            if (statusIco != null) Icon(statusIco, size: 14, color: statusCol),
            if (showLinkBadge && hasLinks)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.link, size: 14, color: Colors.blue),
              ),
            const SizedBox(width: 6),
            Text(
              item.id,
              style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );

    if (!swipeable) return tile;

    return Dismissible(
      key: Key('${item.id}-${item.status}'),
      confirmDismiss: (d) async {
        // izq→der: toggle completed; der→izq: toggle archived
        final to = d == DismissDirection.startToEnd
            ? (item.status == ItemStatus.completed ? ItemStatus.normal : ItemStatus.completed)
            : (item.status == ItemStatus.archived  ? ItemStatus.normal : ItemStatus.archived);
        st.setStatus(item.id, to);
        return false; // no eliminar visualmente
      },
      background: _bg(false),
      secondaryBackground: _bg(true),
      child: tile,
    );
  }

  Widget _bg(bool sec) => Container(
    color: (sec ? Colors.grey : Colors.green).withOpacity(0.15),
    child: Align(
      alignment: sec ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Icon(sec ? Icons.archive : Icons.check, color: sec ? Colors.grey : Colors.green),
      ),
    ),
  );
}
