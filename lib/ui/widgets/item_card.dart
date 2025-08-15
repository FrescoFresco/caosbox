import 'package:flutter/material.dart';
import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/core/models/item.dart';
import 'package:caosbox/core/models/enums.dart';

class ItemCard extends StatelessWidget {
  final Item it; final AppState st; final bool ex;
  final bool showL; final bool cbL; final bool cbR; final bool ck;
  final VoidCallback onT; final VoidCallback onInfo; final VoidCallback? onTapCb;

  const ItemCard({
    super.key,
    required this.it, required this.st, required this.ex,
    required this.onT, required this.onInfo,
    this.showL=true, this.cbL=false, this.cbR=false, this.ck=false, this.onTapCb,
  });

  @override
  Widget build(BuildContext c){
    (IconData?, Color?) statusIcon = switch (it.status) {
      ItemStatus.completed => (Icons.check, Colors.green),
      ItemStatus.archived  => (Icons.archive, Colors.grey),
      _ => (null, null),
    };

    return Dismissible(
      key: Key('${it.id}-${it.status}'),
      confirmDismiss: (d) async {
        final s = it.status;
        if (d == DismissDirection.startToEnd) {
          st.setStatus(it.id, s == ItemStatus.completed ? ItemStatus.normal : ItemStatus.completed);
        } else {
          st.setStatus(it.id, s == ItemStatus.archived ? ItemStatus.normal : ItemStatus.archived);
        }
        return false;
      },
      background: _bg(false), secondaryBackground: _bg(true),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: GestureDetector(
          onLongPress: onInfo,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (cbL) Checkbox(value: ck, onChanged: onTapCb!=null ? (_)=>onTapCb!() : null),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  if (statusIcon.$1 != null) Icon(statusIcon.$1, color: statusIcon.$2, size: 16),
                  if (showL && st.links(it.id).isNotEmpty)
                    const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.link, color: Colors.blue, size: 16)),
                  const SizedBox(width: 6),
                  Flexible(child: Text(it.id, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                  const Spacer(),
                ]),
                const SizedBox(height: 6),
                InkWell(onTap: onT, child: Text(it.text, maxLines: ex?null:1, overflow: ex?null:TextOverflow.ellipsis, style: const TextStyle(fontSize: 14))),
              ])),
              if (cbR) Checkbox(value: ck, onChanged: onTapCb!=null ? (_)=>onTapCb!() : null),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _bg(bool sec)=>Container(
    color:(sec?Colors.grey:Colors.green).withOpacity(0.2),
    child: Align(
      alignment: sec?Alignment.centerRight:Alignment.centerLeft,
      child: const Padding(padding: EdgeInsets.symmetric(horizontal:16), child: Icon(Icons.check)),
    ),
  );
}
