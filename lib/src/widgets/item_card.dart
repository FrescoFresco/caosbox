// lib/src/widgets/item_card.dart

import 'package:flutter/material.dart';
import '../main.dart'; // Item, AppState, ItemStatus

class ItemCard extends StatelessWidget {
  final Item it;
  final AppState st;
  final bool expanded, showLinks, cbLeft, cbRight, checked;
  final VoidCallback onTapTitle, onLongInfo;
  final VoidCallback? onToggleLink;
  const ItemCard({
    super.key,
    required this.it,
    required this.st,
    required this.expanded,
    required this.onTapTitle,
    required this.onLongInfo,
    this.showLinks = true,
    this.cbLeft = false,
    this.cbRight = false,
    this.checked = false,
    this.onToggleLink,
  });
  @override
  Widget build(BuildContext c) {
    final iconData = {
      ItemStatus.completed: Icons.check,
      ItemStatus.archived: Icons.archive
    }[it.status];
    final iconColor = {
      ItemStatus.completed: Colors.green,
      ItemStatus.archived: Colors.grey
    }[it.status];
    return Dismissible(
      key: Key('${it.id}-${it.status}'),
      confirmDismiss: (d) => Behavior.swipe(d, it.status, (s) => st.setStatus(it.id, s)),
      background: Behavior.bg(false),
      secondaryBackground: Behavior.bg(true),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(8)),
        child: GestureDetector(
          onLongPress: onLongInfo,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (cbLeft) Checkbox(value: checked, onChanged: (_) => onToggleLink?.call()),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  if (iconData != null) Icon(iconData, color: iconColor, size: 16),
                  if (showLinks && st.links(it.id).isNotEmpty)
                    const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.link, color: Colors.blue, size: 16)),
                  const SizedBox(width: 6),
                  Text(it.id, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const Spacer(),
                ]),
                const SizedBox(height: 6),
                InkWell(
                  onTap: onTapTitle,
                  child: Text(it.text, maxLines: expanded ? null : 1, overflow: expanded ? null : TextOverflow.ellipsis),
                ),
              ])),
              if (cbRight) Checkbox(value: checked, onChanged: (_) => onToggleLink?.call()),
            ]),
          ),
        ),
      ),
    );
  }
}

class Behavior {
  static Future<bool> swipe(DismissDirection d, ItemStatus s, Function(ItemStatus) on) async {
    final ns = d == DismissDirection.startToEnd
        ? (s == ItemStatus.completed ? ItemStatus.normal : ItemStatus.completed)
        : (s == ItemStatus.archived ? ItemStatus.normal : ItemStatus.archived);
    on(ns);
    return false;
  }
  static Widget bg(bool secondary) => Container(
    color: (secondary ? Colors.grey : Colors.green).withOpacity(0.2),
    child: Align(
      alignment: secondary ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Icon(secondary ? Icons.archive : Icons.check, color: secondary ? Colors.grey : Colors.green),
      ),
    ),
  );
}
