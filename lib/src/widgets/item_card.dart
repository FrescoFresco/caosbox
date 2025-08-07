import 'package:flutter/material.dart';
import 'package:caosbox/src/models/models.dart';     // Item, AppState, ItemStatus
import '../../main.dart' show Style, Behavior;       // Style, Behavior están en main.dart

class ItemCard extends StatelessWidget {
  final Item it;
  final AppState st;
  final bool ex;           // control de expansión
  final bool showLinks;    // antes showL
  final bool cbL;          // checkbox izquierda
  final bool cbR;          // checkbox derecha
  final bool ck;           // checkbox checked
  final VoidCallback onT;  // tap texto
  final VoidCallback onInfo; // long press
  final VoidCallback? onTapCb;

  const ItemCard({
    Key? key,
    required this.it,
    required this.st,
    required this.ex,
    required this.onT,
    required this.onInfo,
    this.showLinks = true,
    this.cbL = false,
    this.cbR = false,
    this.ck = false,
    this.onTapCb,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final iconData = Style.statusIcons[it.status];
    return Dismissible(
      key: Key('${it.id}-${it.status}'),
      confirmDismiss: (d) => Behavior.swipe(d, it.status, (s) => st.setStatus(it.id, s)),
      background: Behavior.bg(false),
      secondaryBackground: Behavior.bg(true),
      child: Container(
        decoration: Style.card,
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: GestureDetector(
          onLongPress: onInfo,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cbL)
                  Checkbox(value: ck, onChanged: onTapCb != null ? (_) => onTapCb!() : null),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        if (iconData != null)
                          Icon(iconData['icon'] as IconData,
                              color: iconData['color'] as Color, size: 16),
                        if (showLinks && st.links(it.id).isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.link, color: Colors.blue, size: 16),
                          ),
                        const SizedBox(width: 6),
                        Flexible(child: Text(it.id, style: Style.id)),
                        const Spacer(),
                      ]),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: onT,
                        child: Text(
                          it.text,
                          maxLines: ex ? null : 1,
                          overflow: ex ? null : TextOverflow.ellipsis,
                          style: Style.content,
                        ),
                      ),
                    ],
                  ),
                ),
                if (cbR)
                  Checkbox(value: ck, onChanged: onTapCb != null ? (_) => onTapCb!() : null),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
