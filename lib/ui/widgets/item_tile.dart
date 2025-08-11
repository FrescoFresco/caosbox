import 'package:flutter/material.dart';
import 'package:caosbox/core/models/item.dart';
import 'package:caosbox/core/models/enums.dart';
import 'package:caosbox/ui/theme/style.dart';

class ItemTile extends StatelessWidget {
  final Item item;
  final dynamic st; // AppState
  final bool expanded;
  final VoidCallback onTap;
  final VoidCallback onInfo;
  final bool swipeable;
  final bool checkbox; // reservado

  const ItemTile({
    super.key,
    required this.item,
    required this.st,
    required this.expanded,
    required this.onTap,
    required this.onInfo,
    this.swipeable = true,
    this.checkbox = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasLinks = st.links(item.id).isNotEmpty;
    final statusIcon = switch (item.status) {
      ItemStatus.completed => Icons.check,
      ItemStatus.archived  => Icons.archive,
      _                    => null,
    };
    final statusColor = switch (item.status) {
      ItemStatus.completed => Colors.green,
      ItemStatus.archived  => Colors.grey,
      _                    => null,
    };

    final child = Container(
      decoration: Style.card,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onLongPress: onInfo,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  if (statusIcon != null) Icon(statusIcon, color: statusColor, size: 16),
                  if (hasLinks) const Padding(
                    padding: EdgeInsets.only(left:4),
                    child: Icon(Icons.link, color: Colors.blue, size:16),
                  ),
                  const SizedBox(width: 6),
                  Flexible(child: Text(item.id, style: Style.id)),
                  const Spacer(),
                ]),
                const SizedBox(height: 6),
                InkWell(
                  onTap: onTap,
                  child: Text(
                    item.text,
                    maxLines: expanded ? null : 1,
                    overflow: expanded ? null : TextOverflow.ellipsis,
                    style: Style.content,
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );

    if (!swipeable) return child;

    return Dismissible(
      key: Key('${item.id}-${item.status}'),
      confirmDismiss: (d) async {
        final next = d == DismissDirection.startToEnd
            ? (item.status == ItemStatus.completed ? ItemStatus.normal : ItemStatus.completed)
            : (item.status == ItemStatus.archived  ? ItemStatus.normal : ItemStatus.archived);
        st.setStatus(item.id, next);
        return false;
      },
      background: _bg(false),
      secondaryBackground: _bg(true),
      child: child,
    );
  }

  Widget _bg(bool sec) => Container(
    color: (sec ? Colors.grey : Colors.green).withValues(alpha: 0.2),
    child: Align(
      alignment: sec ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Icon(sec ? Icons.archive : Icons.check, color: sec ? Colors.grey : Colors.green),
      ),
    ),
  );
}
