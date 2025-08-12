import 'package:flutter/material.dart';

enum SimpleCheckboxSide { none, left, right }

/// Bloque único y simple para TODOS los contextos (B1, B2, Enlaces, Modal).
/// - Base: ExpansionTile (siempre el mismo aspecto)
/// - Checkbox opcional (izquierda/derecha) para select/link
/// - Icono de enlaces opcional (pequeño)
/// - Botón de info opcional (trailing)
class SimpleBlockTile extends StatelessWidget {
  final String id;
  final String text;
  final bool hasLinks;

  final SimpleCheckboxSide checkboxSide;
  final bool checked;
  final VoidCallback? onToggleCheck;

  final VoidCallback? onInfo;

  const SimpleBlockTile({
    super.key,
    required this.id,
    required this.text,
    this.hasLinks = false,
    this.checkboxSide = SimpleCheckboxSide.none,
    this.checked = false,
    this.onToggleCheck,
    this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    final leftCb  = checkboxSide == SimpleCheckboxSide.left
        ? Checkbox(value: checked, onChanged: (_) => onToggleCheck?.call())
        : null;
    final rightCb = checkboxSide == SimpleCheckboxSide.right
        ? Checkbox(value: checked, onChanged: (_) => onToggleCheck?.call())
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leftCb != null) Padding(padding: const EdgeInsets.only(top: 4), child: leftCb),
          Expanded(
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 12),
              title: Row(
                children: [
                  if (hasLinks) const Icon(Icons.link, size: 16, color: Colors.blue),
                  if (hasLinks) const SizedBox(width: 6),
                  Text(id, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              subtitle: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (rightCb != null) rightCb,
                  if (onInfo != null)
                    IconButton(
                      tooltip: 'Detalles',
                      icon: const Icon(Icons.info_outline, size: 18),
                      onPressed: onInfo,
                    ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(text, style: const TextStyle(fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
