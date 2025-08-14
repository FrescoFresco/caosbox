import 'package:flutter/material.dart';
import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/core/models/item.dart';
import 'package:caosbox/core/models/enums.dart';
import 'package:caosbox/domain/search/search_models.dart';

String lbl(ItemType t) => t == ItemType.idea ? 'Idea' : 'Acción';
IconData ico(ItemType t) => t == ItemType.idea ? Icons.lightbulb : Icons.assignment;

void showInfoModal(BuildContext c, Item it, AppState s) {
  showModalBottomSheet(
    context: c,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => InfoModal(id: it.id, st: s),
  );
}

class InfoModal extends StatelessWidget {
  final String id;
  final AppState st;
  const InfoModal({super.key, required this.id, required this.st});

  @override
  Widget build(BuildContext context) {
    final cur = st.getItem(id)!;
    final linked = st.all.where((i)=>st.links(id).contains(i.id)).toList();

    return FractionallySizedBox(
      heightFactor: .9,
      child: Material(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Icon(ico(cur.type)),
              const SizedBox(width: 8),
              Expanded(child: Text('${lbl(cur.type)} • ${cur.id}', style: const TextStyle(fontWeight: FontWeight.bold))),
              if (cur.status != ItemStatus.normal)
                Chip(label: Text(cur.status.name), visualDensity: VisualDensity.compact),
              IconButton(icon: const Icon(Icons.close), onPressed: ()=>Navigator.pop(context)),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Contenido', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(cur.text),
                const SizedBox(height: 12),
                const Text('Relacionado', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                if (linked.isEmpty)
                  const Text('Sin relaciones', style: TextStyle(color: Colors.grey))
                else
                  ...linked.map((li)=>ListTile(
                    dense: true,
                    title: Text(li.text, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(li.id),
                    trailing: Checkbox(
                      value: st.links(cur.id).contains(li.id),
                      onChanged: (_)=>st.toggleLink(cur.id, li.id),
                    ),
                  )),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
