import 'package:flutter/material.dart';
import '../../models/enums.dart';
import '../../models/item.dart';
import '../../state/app_state.dart';

class ItemCard extends StatelessWidget {
  final Item item;
  final AppState st;
  final bool ex;
  final VoidCallback onT;
  final VoidCallback onInfo;

  const ItemCard({
    super.key,
    required this.item,
    required this.st,
    required this.ex,
    required this.onT,
    required this.onInfo,
  });

  @override
  Widget build(BuildContext c) {
    final statusIcon = switch (item.status) {
      ItemStatus.completed => (Icons.check, Colors.green),
      ItemStatus.archived => (Icons.archive, Colors.grey),
      _ => (null, null),
    };

    return Dismissible(
      key: Key('${item.id}-${item.status}'),
      confirmDismiss: (d) async {
        // swipe izq→der: toggle completed; der→izq: toggle archived
        final to = d == DismissDirection.startToEnd
            ? (item.status == ItemStatus.completed ? ItemStatus.normal : ItemStatus.completed)
            : (item.status == ItemStatus.archived ? ItemStatus.normal : ItemStatus.archived);
        st.setStatus(item.id, to);
        return false; // no eliminar
      },
      background: _bg(false),
      secondaryBackground: _bg(true),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(8)),
        child: InkWell(
          onLongPress: onInfo,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (statusIcon.$1 != null) Icon(statusIcon.$1, color: statusIcon.$2, size: 16),
              if (st.links(item.id).isNotEmpty)
                const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.link, size: 16, color: Colors.blue)),
              const SizedBox(width: 6),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(item.id, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                    const Spacer(),
                  ]),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onT,
                    child: Text(
                      item.text,
                      maxLines: ex ? null : 1,
                      overflow: ex ? null : TextOverflow.ellipsis,
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

  Widget _bg(bool sec) => Container(
        color: (sec ? Colors.grey : Colors.green).withOpacity(0.15),
        child: Align(
          alignment: sec ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Icon(sec ? Icons.archive : Icons.check, color: sec ? Colors.grey : Colors.green),
          ),
        ),
      );
}
