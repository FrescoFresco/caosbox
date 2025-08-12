import 'package:flutter/material.dart';

/// En qué lado se pinta el checkbox (o ninguno).
enum TileCheckboxSide { none, left, right }

/// Bloque visual único (sin expandible) con:
/// - Card + InkWell (long-press abre detalles)
/// - Swipe: start→end (completar/normal), end→start (archivar/normal)
/// - Checkbox opcional (izquierda/derecha) para select/link
/// - Franja de estado (2-3 px) en el borde izquierdo
class ContentTile extends StatelessWidget {
  final String id;
  final String text;
  final IconData typeIcon;
  final bool hasLinks;

  /// Colores de estado para la franja (normal → transparente)
  final Color statusColor;

  /// Checkbox lateral
  final TileCheckboxSide checkboxSide;
  final bool checked;
  final VoidCallback? onToggleCheck;

  /// Gestos
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
    final leftCb  = checkboxSide == TileCheckboxSide.left
        ? Checkbox(value: checked, onChanged: (_) => onToggleCheck?.call())
        : null;
    final rightCb = checkboxSide == TileCheckboxSide.right
        ? Checkbox(value: checked, onChanged: (_) => onToggleCheck?.call())
        : null;

    final tile = Card(
      elevation: 0.5,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onLongPress: onLongPress,
        child: SizedBox(
          height: 72,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Franja de estado
              Container(width: 3, color: statusColor),
              // Checkbox izquierdo
              if (leftCb != null)
                Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Center(child: leftCb)),
              // Contenido principal
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fila 1: icono tipo + id + badge links
                      Row(
                        children: [
                          Icon(typeIcon, size: 16),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(id, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                          if (hasLinks) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.link, size: 16, color: Colors.blue),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Fila 2: texto (una línea)
                      Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              // Checkbox derecho
              if (rightCb != null)
                Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Center(child: rightCb)),
            ],
          ),
        ),
      ),
    );

    // Swipe opcional
    return Dismissible(
      key: key ?? ValueKey('tile_$id'),
      confirmDismiss: (d) async {
        if (d == DismissDirection.startToEnd) {
          if (onSwipeStartToEnd != null) await onSwipeStartToEnd!.call();
        } else if (d == DismissDirection.endToStart) {
          if (onSwipeEndToStart != null) await onSwipeEndToStart!.call();
        }
        return false; // no sacamos el tile, sólo aplicamos cambio
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
        child: Icon(secondary ? Icons.archive : Icons.check,
          color: secondary ? Colors.grey : Colors.green),
      ),
    ),
  );
}
