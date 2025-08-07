import 'package:flutter/material.dart';
import 'package:caosbox/main.dart' show AppState, Item; // importa tu modelo central

class ItemCard extends StatelessWidget {
  final Item it;
  final AppState st;
  final bool ex;            // <-- PARAMETRO EX AGREGADO
  final VoidCallback onT;
  final VoidCallback onLongInfo;
  final bool cbR;
  final bool ck;
  final VoidCallback? onTapCb;

  const ItemCard({
    Key? key,
    required this.it,
    required this.st,
    this.ex = false,        // <-- valor por defecto
    required this.onT,
    required this.onLongInfo,
    this.cbR = false,
    this.ck = false,
    this.onTapCb,
  }) : super(key: key);

  @override
  Widget build(BuildContext c) {
    final m = st.statusIcons[it.status];
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
              if (cbR)
                Checkbox(value: ck, onChanged: onTapCb != null ? (_) => onTapCb!() : null),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    if (m != null) Icon(m['icon'] as IconData, color: m['color'] as Color, size: 16),
                    const SizedBox(width: 6),
                    Flexible(child: Text(it.id, style: Style.id)),
                    const Spacer(),
                  ]),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: onT,
                    child: Text(
                      it.text,
                      maxLines: ex ? null : 1,       // <-- usa el parámetro ex
                      overflow: ex ? null : TextOverflow.ellipsis,
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
