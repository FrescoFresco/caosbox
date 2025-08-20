import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repo.dart';
import '../../models/item.dart';
import '../../state/app_state.dart';
import '../widgets/simple_search_field.dart';

class TabLinks extends StatefulWidget {
  const TabLinks({super.key});
  @override
  State<TabLinks> createState() => _TabLinksState();
}

class _TabLinksState extends State<TabLinks> with AutomaticKeepAliveClientMixin {
  String? _leftSel; // id B1 seleccionado
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final repo = context.read<Repo>();
    final st = context.watch<AppState>();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // IZQUIERDA: B1
          Expanded(
            child: Column(
              children: [
                SimpleSearchField(value: st.qLLeft, onChanged: st.setQLLeft, hint: 'Buscar B1…'),
                const SizedBox(height: 8),
                Expanded(
                  child: StreamBuilder<List<Item>>(
                    stream: repo.streamByType(ItemType.b1),
                    builder: (context, snap) {
                      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                      final q = st.qLLeft.toLowerCase();
                      final items = snap.data!
                          .where((e) => e.text.toLowerCase().contains(q) || e.note.toLowerCase().contains(q) || e.tags.any((t) => t.toLowerCase().contains(q)))
                          .toList();
                      return ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (c, i) {
                          final it = items[i];
                          final selected = _leftSel == it.id;
                          return ListTile(
                            selected: selected,
                            leading: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                            title: Text(it.text, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: it.note.isEmpty ? null : Text(it.note, maxLines: 1, overflow: TextOverflow.ellipsis),
                            onTap: () => setState(() => _leftSel = it.id),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 24),

          // DERECHA: B2 con checkboxes de vínculo al seleccionado de la IZQ
          Expanded(
            child: Column(
              children: [
                SimpleSearchField(value: st.qLRight, onChanged: st.setQLRight, hint: 'Buscar B2…'),
                const SizedBox(height: 8),
                Expanded(
                  child: _leftSel == null
                      ? const Center(child: Text('Selecciona un B1 a la izquierda'))
                      : StreamBuilder<Set<String>>(
                          stream: repo.streamLinksOf(_leftSel!),
                          builder: (context, linkSnap) {
                            final linked = linkSnap.data ?? <String>{};
                            return StreamBuilder<List<Item>>(
                              stream: repo.streamByType(ItemType.b2),
                              builder: (context, snap) {
                                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                                final q = st.qLRight.toLowerCase();
                                final items = snap.data!
                                    .where((e) => e.text.toLowerCase().contains(q) || e.note.toLowerCase().contains(q) || e.tags.any((t) => t.toLowerCase().contains(q)))
                                    .toList();
                                return ListView.builder(
                                  itemCount: items.length,
                                  itemBuilder: (c, i) {
                                    final it = items[i];
                                    final ck = linked.contains(it.id);
                                    return CheckboxListTile(
                                      value: ck,
                                      onChanged: (_) => context.read<AppState>().toggleLink(_leftSel!, it.id),
                                      title: Text(it.text, maxLines: 1, overflow: TextOverflow.ellipsis),
                                      subtitle: it.note.isEmpty ? null : Text(it.note, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
