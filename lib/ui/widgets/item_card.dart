import 'package:flutter/material.dart';
import '../../models/item.dart';
import '../../state/app_state.dart';
import '../style.dart';
import 'behavior.dart';

class ItemCard extends StatelessWidget {
  final Item item;
  final AppState st;
  final bool ex;
  final VoidCallback onT, onInfo;
  final Widget? trailing;
  const ItemCard({
    super.key,
    required this.item,
    required this.st,
    required this.ex,
    required this.onT,
    required this.onInfo,
    this.trailing,
  });

  @override Widget build(BuildContext c) {
    final m = Style.statusIcons[item.status];

    return Dismissible(
      key: Key('${item.id}-${item.status}'),
      confirmDismiss: (d) =>
          Behavior.swipe(d, item.status, (s) => st.setStatus(item.id, s)),
      background: Behavior.bg(false),
      secondaryBackground: Behavior.bg(true),
      child: Container(
        decoration: Style.card,
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: GestureDetector(
          onLongPress: onInfo,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  if (m != null)
                    Icon(m['icon'] as IconData,
                        color: m['color'] as Color, size: 16),
                  if (st.links(item.id).isNotEmpty)
                    const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.link, color: Colors.blue, size: 16)),
                  const SizedBox(width: 6),
                  Flexible(child: Text(item.id, style: Style.id)),
                ]),
                const SizedBox(height: 6),
                InkWell(
                  onTap: onT,
                  child: Text(
                    item.text,
                    maxLines: ex ? null : 1,
                    overflow: ex ? null : TextOverflow.ellipsis,
                    style: Style.content,
                  ),
                ),
              ])),
              if (trailing != null) trailing!,
            ]),
          ),
        ),
      ),
    );
  }
}
