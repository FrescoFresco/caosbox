import 'package:flutter/material.dart';

/// Lado del checkbox (o ninguno).
enum TileCheckboxSide { none, left, right }

/// Bloque visual único sin expandibles:
/// - Card + ListTile (Material nativo)
/// - Long-press abre detalles
/// - Swipe start→end = completar/normal; end→start = archivar/normal
/// - Checkbox opcional a izquierda/derecha (select/link)
class ContentTile extends StatelessWidget {
  final String id;
  final String text;
  final IconData typeIcon;
  final bool hasLinks;

  /// Color para señalar el estado (usado en un punto sutil)
  final Color statusColor;

  final TileCheckboxSide checkboxSide;
  final bool checked;
  final VoidCallback? onToggleCheck;

  final VoidCallback onLongPress;
  final Future<void> Function()? onSwipeStartToEnd; // completar/normal
  final Future<void> Function()? onSwipeEndToStart; // archivar/normal

  const ContentTile({
    super.key,
    required this.id,
    required this.text,
    required this.typeIcon,
    required this.hasLinks,
    required this.statusColor,
    required this.checkboxSide,
    required this.checked,
    required this.onToggleCheck,
    required this.onLongPress,
    this.onSwipeStartToEnd,
    this.onSwipeEndToStart,
  });

  @override
  Widget build(BuildContext context) {
    // Checkbox en el lado que toque
    final leftCb  = checkboxSide == TileCheckboxSide.left
        ? Checkbox(value: checked, onChanged: (_) => onToggleCheck?.call())
        : null;
    final rightCb = checkboxSide == TileCheckboxSide.right
        ? Checkbox(value: checked, onChanged: (_) => onToggleCheck?.call())
        : null;

    // Leading compacto: [checkbox izq?] icono tipo
    Widget? leading;
    if (leftCb != null) {
      leading = Row(
        mainAxisSize: MainAxisSize.min,
        children: [leftCb, const SizedBox(width: 4), Icon(typeIcon, size: 18)],
      );
    } else {
      leading = Icon(typeIcon, size: 18);
    }

    // Trailing: [checkbox der?] (en list no hay trailing)
    Widget? trailing = rightCb;

    // Título: • (punto color estado) + ID + 🔗 si tiene enlaces
    final title = Row(
      children: [
        Icon(Icons.circle, size: 6, color: statusColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            id,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        if (hasLinks) const SizedBox(width: 8),
        if (hasLinks) const Icon(Icons.link, size: 16, color: Colors.blue),
      ],
    );

    // Subtítulo: texto en una línea
    final subtitle = Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 14),
    );

    final tile = Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onLongPress: onLongPress,
        // tap no hace nada (evitamos confusión)
      ),
    );

    // Swipe con Dismissible (acciones, sin quitar el tile)
    return Dismissible(
      key: key ?? ValueKey('tile_$id'),
      confirmDismiss: (d) async {
        if (d == DismissDirection.startToEnd) {
          if (onSwipeStartToEnd != null) await onSwipeStartToEnd!.call();
        } else if (d == DismissDirection.endToStart) {
          if (onSwipeEndToStart != null) await onSwipeEndToStart!.call();
        }
        return false;
      },
      background: _swipeBg(false),
      secondaryBackground: _swipeBg(true),
      child: tile,
    );
  }

  Widget _swipeBg(bool secondary) => Container(
    color: (secondary ? Colors.grey : Colors.green).withOpacity(0.12),
    child: Align(
      alignment: secondary ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Icon(
          secondary ? Icons.archive : Icons.check,
          color: secondary ? Colors.grey : Colors.green,
        ),
      ),
    ),
  );
}
