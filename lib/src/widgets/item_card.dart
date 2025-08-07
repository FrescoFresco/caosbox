// lib/src/widgets/item_card.dart

import 'package:flutter/material.dart';
import '../models/models.dart'           show Item, ItemStatus;
import '../../main.dart'               show Style, Behavior;
import 'info_modal.dart'               show showInfoModal;

class ItemCard extends StatelessWidget {
  final Item it;
  final dynamic st; // models.AppState
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const ItemCard({
    super.key,
    required this.it,
    required this.st,
    this.isExpanded = false,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext c) {
    final iconData = Style.statusIcons[it.status];
    return Dismissible(
      key: Key('${it.id}-${it.status}'),
      confirmDismiss: (d) {
        final next = d == DismissDirection.startToEnd
            ? (it.status == ItemStatus.completed ? ItemStatus.normal : ItemStatus.completed)
            : (it.status == ItemStatus.archived ? ItemStatus.normal : ItemStatus.archived);
        st.setStatus(it.id, next);
        return Future.value(false);
      },
      background: Behavior.bg(false),
      secondaryBackground: Behavior.bg(true),
      child: Container(
        decoration: Style.card,
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: GestureDetector(
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isExpanded)
                  Checkbox(value: true, onChanged: (_) {}),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        if (iconData != null)
                          Icon(iconData['icon'] as IconData,
                              color: iconData['color'] as Color, size: 16),
                        const SizedBox(width: 6),
                        Flexible(child: Text(it.id, style: Style.id)),
                        const Spacer(),
                      ]),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: onTap,
                        child: Text(
                          it.text,
                          maxLines: isExpanded ? null : 1,
                          overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                          style: Style.content,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
