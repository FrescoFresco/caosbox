import 'package:flutter/material.dart';
import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/core/models/enums.dart';
import 'package:caosbox/core/models/item.dart';
import 'package:caosbox/config/blocks.dart';
import 'package:caosbox/domain/search/search_models.dart';
import 'package:caosbox/core/utils/tri.dart';

/// Pantalla genérica para bloques de ItemType (B1/B2).
class GenericScreen extends StatefulWidget {
  final Block block;
  final AppState st;
  const GenericScreen({super.key, required this.block, required this.st});

  @override
  State<GenericScreen> createState() => _GenericScreenState();
}

class _GenericScreenState extends State<GenericScreen> with AutomaticKeepAliveClientMixin {
  // Búsqueda avanzada (si la usas aquí): arranca vacía.
  SearchSpec _spec = const SearchSpec(root: GroupNode(op: Op.and, children: []));
  final _composer = TextEditingController();
  final _quick = TextEditingController();
  late final ItemType _t = widget.block.type!;

  @override
  void dispose() {
    _composer.dispose();
    _quick.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  List<Item> _applyQuickAndSpec(List<Item> src) {
    // Quick text → OR en id|content|note AND con _spec
    final q = _quick.text.trim();
    SearchSpec spec = _spec;
    if (q.isNotEmpty) {
      final tokens = [Token(q, Tri.include)];
      final orGroup = GroupNode(
        op: Op.or,
        children: [
          LeafNode(clause: TextClause(element: 'id', tokens: tokens)),
          LeafNode(clause: TextClause(element: 'content', tokens: tokens)),
          LeafNode(clause: TextClause(element: 'note', tokens: tokens)),
        ],
      );
      spec = SearchSpec(
        root: GroupNode(op: Op.and, children: [spec.root, orGroup]),
      );
    }

    bool evalNode(Item it, QueryNode n) {
      if (n is LeafNode) return _evalClause(it, n.clause);
      if (n is GroupNode) {
        if (n.children.isEmpty) return true;
        bool acc = evalNode(it, n.children.first);
        for (int i = 1; i < n.children.length; i++) {
          final cur = evalNode(it, n.children[i]);
          if (n.op == Op.and) {
            acc = acc && cur;
            if (!acc) return false;
          } else {
            acc = acc || cur;
            if (acc) return true;
          }
        }
        return acc;
      }
      return true;
    }

    return [
      for (final it in src) if (evalNode(it, spec.root)) it,
    ];
  }

  bool _evalClause(Item it, Clause c) {
    final st = widget.st;
    if (c is TextClause) {
      final src = switch (c.element) {
        'id' => it.id,
        'note' => st.note(it.id),
        _ => it.text,
      }.toLowerCase();

      if (c.presence != Tri.off) {
        final has = src.trim().isNotEmpty;
        if (c.presence == Tri.include && !has) return false;
        if (c.presence == Tri.exclude && has) return false;
      }

      bool contains(String a, String b) => b.isEmpty || a.contains(b);
      bool prefix(String a, String b) => b.isEmpty || a.startsWith(b);
      bool exact(String a, String b) => a == b;
      final cmp = switch (c.match) {
        TextMatch.prefix => prefix,
        TextMatch.exact => exact,
        _ => contains,
      };

      for (final t in c.tokens) {
        final hit = cmp(src, t.t.toLowerCase());
        if (t.mode == Tri.include && !hit) return false;
        if (t.mode == Tri.exclude && hit) return false;
      }
      return true;
    } else if (c is FlagClause) {
      switch (c.field) {
        case 'type':
          final v = it.type.name; // 'idea'|'action'
          if (c.include.isNotEmpty && !c.include.contains(v)) return false;
          if (c.exclude.contains(v)) return false;
          return true;
        case 'status':
          final v = it.status.name.toLowerCase(); // 'normal'|'completed'|'archived'
          if (c.include.isNotEmpty && !c.include.contains(v)) return false;
          if (c.exclude.contains(v)) return false;
          return true;
        case 'hasLinks':
          if (c.mode == Tri.off) return true;
          final has = st.links(it.id).isNotEmpty;
          return c.mode == Tri.include ? has : !has;
        case 'relation':
          if (c.mode == Tri.off) return true;
          final anchor = (c.anchorId ?? '').trim();
          if (anchor.isEmpty) return true;
          final isRel = st.links(anchor).contains(it.id);
          return c.mode == Tri.include ? isRel : !isRel;
      }
    }
    return true;
  }

  void _add() {
    final v = _composer.text.trim();
    if (v.isEmpty) return;
    widget.st.add(_t, v);
    _composer.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final st = widget.st;
    final base = st.items(_t);
    final filtered = _applyQuickAndSpec(base);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Composer simple
          Row(children: [
            Expanded(
              child: TextField(
                controller: _composer,
                decoration: InputDecoration(
                  hintText: _t == ItemType.idea ? 'Escribe tu idea…' : 'Describe la acción…',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                minLines: 1, maxLines: 4,
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(onPressed: _add, child: const Text('Agregar')),
          ]),
          const SizedBox(height: 12),

          // Barra de búsqueda rápida + botón filtros (avanzado)
          Row(children: [
            Expanded(
              child: TextField(
                controller: _quick,
                decoration: const InputDecoration(
                  hintText: 'Buscar…',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Filtros avanzados',
              icon: const Icon(Icons.tune),
              onPressed: () async {
                // Aquí abrirías tu modal real de filtros y devolverías un SearchSpec
                // Para compilar sin tu UI, dejamos un ejemplo trivial:
                final newSpec = await showDialog<SearchSpec>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Filtros avanzados'),
                    content: const Text('Aqui abre tu modal real y vuelve con un SearchSpec.'),
                    actions: [
                      TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text('Cancelar')),
                      FilledButton(
                        onPressed: (){
                          Navigator.pop(ctx, const SearchSpec(root: GroupNode(op: Op.and, children: [])));
                        },
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
                if (newSpec != null) setState(() => _spec = newSpec);
              },
            ),
          ]),
          const SizedBox(height: 8),

          // Lista
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final it = filtered[i];
                return Card(
                  child: ListTile(
                    title: Text(it.text),
                    subtitle: Text('${it.id} • ${it.status.name}'),
                    trailing: st.links(it.id).isNotEmpty ? const Icon(Icons.link, size: 18, color: Colors.blue) : null,
                    onLongPress: () => showInfoModal(context, it, st),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ===== Modal Info reutilizado (firma existente) =====
String lbl(ItemType t) => t == ItemType.idea ? 'Idea' : 'Acción';
IconData ico(ItemType t) => t == ItemType.idea ? Icons.lightbulb : Icons.assignment;

void showInfoModal(BuildContext c, Item it, AppState s) {
  showModalBottomSheet(
    context: c,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _InfoModal(id: it.id, st: s),
  );
}

class _InfoModal extends StatelessWidget {
  final String id;
  final AppState st;
  const _InfoModal({required this.id, required this.st});

  @override
  Widget build(BuildContext context) {
    final cur = st.getItem(id)!;
    final linked = st.all.where((i) => st.links(id).contains(i.id)).toList();
    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Material(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Icon(ico(cur.type)),
                const SizedBox(width: 8),
                Expanded(child: Text('${lbl(cur.type)} • ${cur.id}', style: const TextStyle(fontWeight: FontWeight.bold))),
                if (cur.status != ItemStatus.normal)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Chip(label: Text(cur.status.name), visualDensity: VisualDensity.compact),
                  ),
                IconButton(tooltip: 'Cerrar', icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
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
                  const Text('Notas', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(st.note(cur.id).isEmpty ? '—' : st.note(cur.id)),
                  const SizedBox(height: 12),
                  const Text('Relacionado', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  if (linked.isEmpty)
                    const Text('Sin relaciones', style: TextStyle(color: Colors.grey))
                  else
                    ...linked.map((li) => ListTile(
                          dense: true,
                          title: Text(li.text, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(li.id),
                          trailing: IconButton(
                            icon: Icon(
                              st.links(cur.id).contains(li.id) ? Icons.check_box : Icons.check_box_outline_blank,
                            ),
                            onPressed: () => st.toggleLink(cur.id, li.id),
                          ),
                          onTap: () => showInfoModal(context, li, st),
                        )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
