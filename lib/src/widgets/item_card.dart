import 'package:flutter/material.dart';
import '../../main.dart' as root; // para Style y Behavior
import '../models/models.dart' as models;

class ItemCard extends StatelessWidget {
  final models.Item it;
  final models.AppState st;
  final bool ex;
  final VoidCallback onT;
  final VoidCallback onInfo;
  final bool showL, cbL, cbR, ck;
  final VoidCallback? onTapCb;

  const ItemCard({
    Key? key,
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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final m = root.Style.statusIcons[it.status];
    return Dismissible(
      key: Key('${it.id}-${it.status}'),
      confirmDismiss: (d) =>
          root.Behavior.swipe(d, it.status, (s) => st.setStatus(it.id, s)),
      background: root.Behavior.bg(false),
      secondaryBackground: root.Behavior.bg(true),
      child: Container(
        decoration: root.Style.card,
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: GestureDetector(
          onLongPress: onInfo,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cbL)
                  Checkbox(value: ck, onChanged: (_) => onTapCb?.call()),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        if (m != null)
                          Icon(m['icon'] as IconData,
                              color: m['color'] as Color, size: 16),
                        if (showL && st.links(it.id).isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child:
                                Icon(Icons.link, color: Colors.blue, size: 16),
                          ),
                        const SizedBox(width: 6),
                        Flexible(child: Text(it.id, style: root.Style.id)),
                        const Spacer(),
                      ]),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: onT,
                        child: Text(
                          it.text,
                          maxLines: ex ? null : 1,
                          overflow: ex ? null : TextOverflow.ellipsis,
                          style: root.Style.content,
                        ),
                      ),
                    ],
                  ),
                ),
                if (cbR)
                  Checkbox(value: ck, onChanged: (_) => onTapCb?.call()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
