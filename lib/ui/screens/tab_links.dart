import 'package:flutter/material.dart';
import '../../data/fire_repo.dart';
import '../../models/item.dart';
import '../widgets/item_tile.dart';
import '../widgets/simple_search_field.dart';

class TabLinks extends StatefulWidget {
  final FireRepo repo;
  const TabLinks({super.key, required this.repo});

  @override
  State<TabLinks> createState() => _TabLinksState();
}

class _TabLinksState extends State<TabLinks> {
  String qL = '';
  String qR = '';
  String? selL;
  String? selR;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Item>>(
      stream: widget.repo.watchAll(),
      builder: (ctx, snapItems) {
        if (snapItems.hasError) return Center(child: Text('Error: ${snapItems.error}'));
        final all = snapItems.data ?? [];

        final left = all.where((e) => e.type == ItemType.idea && (qL.isEmpty || _match(e, qL))).toList();
        final right = all.where((e) => e.type == ItemType.action && (qR.isEmpty || _match(e, qR))).toList();

        return StreamBuilder<Map<String, Set<String>>>(
          stream: widget.repo.watchLinks(),
          builder: (ctx, snapLinks) {
            final links = snapLinks.data ?? <String, Set<String>>{};

            final canLink = selL != null && selR != null;
            final isLinked = canLink
                ? (links[selL!] ?? const {}).contains(selR!) ||
                    (links[selR!] ?? const {}).contains(selL!)
                : false;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: SimpleSearchField(
                          value: qL,
                          onChanged: (v) => setState(() => qL = v),
                          hint: 'Buscar Ideas (izquierda)…',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SimpleSearchField(
                          value: qR,
                          onChanged: (v) => setState(() => qR = v),
                          hint: 'Buscar Acciones (derecha)…',
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: canLink
                            ? () async {
                                await widget.repo.toggleLink(selL!, selR!);
                                setState(() {}); // refresco rápido
                              }
                            : null,
                        icon: Icon(isLinked ? Icons.link_off : Icons.link),
                        label: Text(isLinked ? 'Quitar enlace' : 'Crear enlace'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _colList(
                          left,
                          selectedId: selL,
                          onSelect: (id) => setState(() => selL = id == selL ? null : id),
                          title: 'Ideas',
                          links: links,
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: _colList(
                          right,
                          selectedId: selR,
                          onSelect: (id) => setState(() => selR = id == selR ? null : id),
                          title: 'Acciones',
                          links: links,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _match(Item e, String q) =>
      e.id.toLowerCase().contains(q.toLowerCase()) ||
      e.text.toLowerCase().contains(q.toLowerCase()) ||
      e.note.toLowerCase().contains(q.toLowerCase());

  Widget _colList(
    List<Item> data, {
    required String? selectedId,
    required ValueChanged<String> onSelect,
    required String title,
    required Map<String, Set<String>> links,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Text('(${data.length})', style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: data.isEmpty
              ? const Center(child: Text('Sin elementos'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: data.length,
                  itemBuilder: (ctx, i) {
                    final it = data[i];
                    final sel = it.id == selectedId;
                    final deg = (links[it.id] ?? const {}).length;
                    return ItemTile(
                      it: it,
                      selectable: true,
                      selected: sel,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.link, size: 16),
                          Text(' $deg'),
                          const SizedBox(width: 8),
                        ],
                      ),
                      onTap: () => onSelect(it.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
