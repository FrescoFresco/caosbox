import 'package:flutter/material.dart';
import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/core/models/item.dart';
import 'package:caosbox/core/models/enums.dart';
import 'package:caosbox/core/utils/tri.dart';
import 'package:caosbox/domain/search/search_models.dart';

/// Bloque de contenido reutilizable para un ItemType (lista + buscador + composer).
class ContentBlock extends StatefulWidget {
  final AppState st;
  final ItemType type;
  const ContentBlock({super.key, required this.st, required this.type});

  @override
  State<ContentBlock> createState() => _ContentBlockState();
}

class _ContentBlockState extends State<ContentBlock> {
  final _composer = TextEditingController();
  final _quick = TextEditingController();
  SearchSpec _spec = const SearchSpec(root: GroupNode(op: Op.and, children: []));

  @override
  void dispose() { _composer.dispose(); _quick.dispose(); super.dispose(); }

  void _add() {
    final v = _composer.text.trim();
    if (v.isEmpty) return;
    widget.st.add(widget.type, v);
    _composer.clear();
    setState(() {});
  }

  List<Item> _apply(AppState st, Iterable<Item> base) {
    // Aplica spec + quick (OR en id|content|note)
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
      spec = SearchSpec(root: GroupNode(op: Op.and, children: [spec.root, orGroup]));
    }

    bool evalNode(Item it, QueryNode n) {
      if (n is LeafNode) return _evalClause(st, it, n.clause);
      if (n is GroupNode) {
        if (n.children.isEmpty) return true;
        bool acc = evalNode(it, n.children.first);
        for (int i = 1; i < n.children.length; i++) {
          final cur = evalNode(it, n.children[i]);
          if (n.op == Op.and) {
            acc = acc && cur; if (!acc) return false;
          } else {
            acc = acc || cur; if (acc) return true;
          }
        }
        return acc;
      }
      return true;
    }

    final out = <Item>[];
    for (final it in base) {
      if (evalNode(it, spec.root)) out.add(it);
    }
    return out;
  }

  bool _evalClause(AppState st, Item it, Clause c) {
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
      final cmp = switch (c.match) { TextMatch.prefix => prefix, TextMatch.exact => exact, _ => contains };

      for (final t in c.tokens) {
        final hit = cmp(src, t.t.toLowerCase());
        if (t.mode == Tri.include && !hit) return false;
        if (t.mode == Tri.exclude && hit) return false;
      }
      return true;
    } else if (c is FlagClause) {
      switch (c.field) {
        case 'type':
          final v = it.type.name;
          if (c.include.isNotEmpty && !c.include.contains(v)) return false;
          if (c.exclude.contains(v)) return false;
          return true;
        case 'status':
          final v = it.status.name.toLowerCase();
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

  @override
  Widget build(BuildContext context) {
    final st = widget.st;
    final base = st.items(widget.type);
    final items = _apply(st, base);

    return Column(children: [
      Row(children: [
        Expanded(
          child: TextField(
            controller: _composer,
            decoration: InputDecoration(
              hintText: widget.type == ItemType.idea ? 'Escribe tu idea…' : 'Describe la acción…',
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
            onChanged: (_)=>setState((){}),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.tune),
          onPressed: () async {
            // Abre tu UI real de filtros. Aquí dejamos un spec vacío por defecto:
            final s = await showDialog<SearchSpec>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Filtros avanzados'),
                content: const Text('Inserta aquí tu modal de filtros.'),
                actions: [
                  TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text('Cancelar')),
                  FilledButton(onPressed: ()=>Navigator.pop(ctx, const SearchSpec(root: GroupNode(op: Op.and, children: []))), child: const Text('OK')),
                ],
              ),
            );
            if (s != null) setState(()=>_spec = s);
          },
        ),
      ]),
      const SizedBox(height: 8),
      Expanded(
        child: ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, i) {
            final it = items[i];
            return Card(
              child: ListTile(
                title: Text(it.text, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text('${it.id} • ${it.status.name}'),
                trailing: st.links(it.id).isNotEmpty ? const Icon(Icons.link, size: 18, color: Colors.blue) : null,
                onLongPress: ()=>_showInfo(context, it, st),
              ),
            );
          },
        ),
      ),
    ]);
  }

  void _showInfo(BuildContext context, Item it, AppState st) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _InfoModalMini(it: it, st: st),
    );
  }
}

class _InfoModalMini extends StatelessWidget {
  final Item it;
  final AppState st;
  const _InfoModalMini({required this.it, required this.st});

  @override
  Widget build(BuildContext context) {
    final linked = st.all.where((i)=>st.links(it.id).contains(i.id)).toList();
    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Material(
        child: Column(
          children: [
            ListTile(
              title: Text('${it.id} • ${it.status.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(it.text),
              trailing: IconButton(icon: const Icon(Icons.close), onPressed: ()=>Navigator.pop(context)),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Relacionado', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  if (linked.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Sin relaciones', style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ...linked.map((li)=>ListTile(
                      title: Text(li.text, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(li.id),
                      trailing: Checkbox(
                        value: st.links(it.id).contains(li.id),
                        onChanged: (_)=>st.toggleLink(it.id, li.id),
                      ),
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
