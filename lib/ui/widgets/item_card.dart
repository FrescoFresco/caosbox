import 'package:flutter/material.dart';
import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/core/models/enums.dart';
import 'package:caosbox/core/models/item.dart';

class ItemCard extends StatelessWidget {
  final Item it; final AppState st; final bool ex, showL, cbL, cbR, ck;
  final VoidCallback onT, onInfo; final VoidCallback? onTapCb;

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
    final statusIcon = switch (it.status) {
      ItemStatus.completed => (Icons.check, Colors.green),
      ItemStatus.archived => (Icons.archive, Colors.grey),
      _ => null,
    };

    return Dismissible(
      key: Key('${it.id}-${it.status}'),
      confirmDismiss: (d) => _Behavior.swipe(d, it.status, (s) => st.setStatus(it.id, s)),
      background: _Behavior.bg(false),
      secondaryBackground: _Behavior.bg(true),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Card.outlined(
          child: InkWell(
            onTap: onT,
            onLongPress: onInfo,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (cbL) Checkbox(value: ck, onChanged: onTapCb != null ? (_) => onTapCb!() : null),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    if (statusIcon != null) Icon(statusIcon.$1, color: statusIcon.$2, size: 16),
                    if (showL && st.links(it.id).isNotEmpty) const Padding(
                      padding: EdgeInsets.only(left: 4), child: Icon(Icons.link, color: Colors.blue, size: 16)),
                    const SizedBox(width: 6),
                    Flexible(child: Text(it.id, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600))),
                    const Spacer(),
                  ]),
                  const SizedBox(height: 6),
                  Text(
                    it.text,
                    maxLines: ex ? null : 1,
                    overflow: ex ? null : TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                ])),
                if (cbR) Checkbox(value: ck, onChanged: onTapCb != null ? (_) => onTapCb!() : null),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _Behavior {
  static Future<bool> swipe(DismissDirection d, ItemStatus s, Function(ItemStatus) on) async {
    on(d == DismissDirection.startToEnd
        ? (s == ItemStatus.completed ? ItemStatus.normal : ItemStatus.completed)
        : (s == ItemStatus.archived ? ItemStatus.normal : ItemStatus.archived));
    return false;
  }

  static Widget bg(bool sec) => Container(
        color: (sec ? Colors.grey : Colors.green).withOpacity(0.2),
        child: Align(
          alignment: sec ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Icon(sec ? Icons.archive : Icons.check, color: sec ? Colors.grey : Colors.green),
          ),
        ),
      );
}
