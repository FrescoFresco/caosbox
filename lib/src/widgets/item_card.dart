// lib/src/widgets/item_card.dart
import 'package:flutter/material.dart';
import '../models/item.dart';
import '../models/app_state.dart';
import '../utils/style.dart';
import '../utils/behavior.dart';

class ItemCard extends StatelessWidget {
  final Item it;
  final AppState st;
  final VoidCallback onTap;
  final VoidCallback onLongInfo;
  const ItemCard({
    super.key,
    required this.it,
    required this.st,
    required this.onTap,
    required this.onLongInfo,
  });

  @override
  Widget build(BuildContext c) {
    final m = Style.statusIcons[it.status];
    return Dismissible(
      key: Key('${it.id}-${it.status}'),
      confirmDismiss: (d) => Behavior.swipe(d, it.status, (s) => st.setStatus(it.id, s)),
      background: Behavior.bg(false),
      secondaryBackground: Behavior.bg(true),
      child: Container(
        decoration: Style.card,
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: GestureDetector(
          onLongPress: onLongInfo,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    if (m != null) Icon(m['icon'] as IconData, color: m['color'] as Color, size: 16),
                    if (st.links(it.id).isNotEmpty)
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
                    onTap: onTap,
                    child: Text(
                      it.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Style.content,
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
