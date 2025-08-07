import 'package:flutter/material.dart';
import '../models/models.dart';     // Item, ItemStatus, AppState
import '../../main.dart';           // Style, Behavior (desde tu main.dart)
import 'info_modal.dart';           // showInfoModal

class ItemCard extends StatelessWidget {
  final Item it;
  final AppState st;
  final bool ex, showL, cbL, cbR, ck;
  final VoidCallback onT, onInfo;
  final VoidCallback? onTapCb;
  const ItemCard({
    super.key,
    required this.it,
    required this.st,
    required this.ex,
    required this.onT,
    required this.onInfo,
    this.showL = true,
    this.cbL = false,
    this.cbR = false,
    this.ck = false,
    this.onTapCb,
  });

  @override
  Widget build(BuildContext c) {
    final iconData = Style.statusIcons[it.status];
    return Dismissible(
      key: Key('${it.id}-${it.status}'),
      confirmDismiss: (d) => Behavior.swipe(
        d,
        it.status,
        (s) => st.setStatus(it.id, s),
      ),
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
                  Checkbox(
                    value: ck,
                    onChanged: onTapCb != null ? (_) => onTapCb!() : null,
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        if (iconData != null)
                          Icon(iconData['icon'] as IconData, color: iconData['color'] as Color, size: 16),
                        if (showL && st.links(it.id).isNotEmpty)
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
                  Checkbox(
                    value: ck,
                    onChanged: onTapCb != null ? (_) => onTapCb!() : null,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
