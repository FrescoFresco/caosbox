import 'package:flutter/material.dart';
import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/core/models/item.dart';
import 'package:caosbox/core/models/enums.dart';
import 'package:caosbox/domain/search/search_models.dart';
import 'package:caosbox/core/utils/tri.dart';

/// Bloque “Enlaces”: dos columnas con el mismo buscador/quick.
class LinksBlock extends StatefulWidget {
  final AppState state;
  final void Function(BuildContext, ItemType)? onOpenFilters; // por compatibilidad
  const LinksBlock({super.key, required this.state, this.onOpenFilters});

  @override
  State<LinksBlock> createState() => _LinksBlockState();
}

class _LinksBlockState extends State<LinksBlock> with AutomaticKeepAliveClientMixin {
  String? _sel; // seleccionado a la izquierda
  final _qL = TextEditingController();
  final _qR = TextEditingController();

  SearchSpec _leftSpec  = const SearchSpec(root: GroupNode(op: Op.and, children: []));
  SearchSpec _rightSpec = const SearchSpec(root: GroupNode(op: Op.and, children: []));

  @override
  void dispose() { _qL.dispose(); _qR.dispose(); super.dispose(); }

  @override
  bool get wantKeepAlive => true;

  List<Item> _apply(AppState st, Iterable<Item> base, String quick, SearchSpec spec) {
    final q = quick.trim();
    SearchSpec s = spec;
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
      s = SearchSpec(root: GroupNode(op: Op.and, children: [s.root, orGroup]));
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
      if (evalNode(it, s.root)) out.add(it);
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
    super.build(context);
    final st = widget.state;

    final leftBase  = st.all;
    final rightBase = st.all.where((i) => i.id != _sel);

    final left  = _apply(st, leftBase,  _qL.text, _leftSpec);
    final right = _apply(st, rightBase, _qR.text, _rightSpec);

    Widget col({
      required String title,
      required TextEditingController q,
      required VoidCallback onFilters,
      required List<Item> items,
      required bool Function(Item) checked,
      required void Function(Item) onTapCheck,
      required void Function(Item) onTapTile,
      bool checkLeft = false,
    }) {
      return Column(children: [
        Align(alignment: Alignment.centerLeft, child: Padding(
          padding: const EdgeInsets.fromLTRB(12,12,12,8),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        )),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: q,
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
            IconButton(icon: const Icon(Icons.tune), onPressed: onFilters),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) {
              final it = items[i];
              final ck = checked(it);
              return Card(
                child: ListTile(
                  leading: checkLeft ? Checkbox(value: ck, onChanged: (_)=>onTapCheck(it)) : null,
                  trailing: !checkLeft ? Checkbox(value: ck, onChanged: (_)=>onTapCheck(it)) : null,
                  title: Text(it.text, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(it.id),
                  onTap: ()=>onTapTile(it),
                ),
              );
            },
          ),
        ),
      ]);
    }

    return Column(children: [
      const SizedBox(height: 8),
      Expanded(
        child: OrientationBuilder(
          builder: (ctx, o) {
            final body = o == Orientation.portrait
                ? Column(children: [
                    Expanded(child: col(
                      title: 'Seleccionar:',
                      q: _qL,
                      onFilters: () async {
                        // Sustituye por tu modal real de filtros y asigna _leftSpec
                        final s = await showDialog<SearchSpec>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Filtros avanzados (izq)'),
                            content: const Text('Aquí tu UI de filtros.'),
                            actions: [
                              TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text('Cancelar')),
                              FilledButton(onPressed: ()=>Navigator.pop(ctx, const SearchSpec(root: GroupNode(op: Op.and, children: []))), child: const Text('OK')),
                            ],
                          ),
                        );
                        if (s != null) setState(()=>_leftSpec = s);
                      },
                      items: left,
                      checked: (it)=>_sel == it.id,
                      onTapCheck: (it)=>setState(()=>_sel = _sel == it.id ? null : it.id),
                      onTapTile: (it)=>setState(()=>_sel = _sel == it.id ? null : it.id),
                      checkLeft: false,
                    )),
                    const Divider(height: 1),
                    Expanded(child: col(
                      title: 'Conectar con:',
                      q: _qR,
                      onFilters: () async {
                        final s = await showDialog<SearchSpec>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Filtros avanzados (der)'),
                            content: const Text('Aquí tu UI de filtros.'),
                            actions: [
                              TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text('Cancelar')),
                              FilledButton(onPressed: ()=>Navigator.pop(ctx, const SearchSpec(root: GroupNode(op: Op.and, children: []))), child: const Text('OK')),
                            ],
                          ),
                        );
                        if (s != null) setState(()=>_rightSpec = s);
                      },
                      items: right,
                      checked: (it)=> _sel!=null && st.links(_sel!).contains(it.id),
                      onTapCheck: (it){ if (_sel!=null) setState(()=>st.toggleLink(_sel!, it.id)); },
                      onTapTile: (it){ if (_sel!=null) setState(()=>st.toggleLink(_sel!, it.id)); },
                      checkLeft: true,
                    )),
                  ])
                : Row(children: [
                    Expanded(child: col(
                      title: 'Seleccionar:',
                      q: _qL,
                      onFilters: () async {
                        final s = await showDialog<SearchSpec>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Filtros avanzados (izq)'),
                            content: const Text('Aquí tu UI de filtros.'),
                            actions: [
                              TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text('Cancelar')),
                              FilledButton(onPressed: ()=>Navigator.pop(ctx, const SearchSpec(root: GroupNode(op: Op.and, children: []))), child: const Text('OK')),
                            ],
                          ),
                        );
                        if (s != null) setState(()=>_leftSpec = s);
                      },
                      items: left,
                      checked: (it)=>_sel == it.id,
                      onTapCheck: (it)=>setState(()=>_sel = _sel == it.id ? null : it.id),
                      onTapTile: (it)=>setState(()=>_sel = _sel == it.id ? null : it.id),
                      checkLeft: false,
                    )),
                    const VerticalDivider(width: 1),
                    Expanded(child: col(
                      title: 'Conectar con:',
                      q: _qR,
                      onFilters: () async {
                        final s = await showDialog<SearchSpec>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Filtros avanzados (der)'),
                            content: const Text('Aquí tu UI de filtros.'),
                            actions: [
                              TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text('Cancelar')),
                              FilledButton(onPressed: ()=>Navigator.pop(ctx, const SearchSpec(root: GroupNode(op: Op.and, children: []))), child: const Text('OK')),
                            ],
                          ),
                        );
                        if (s != null) setState(()=>_rightSpec = s);
                      },
                      items: right,
                      checked: (it)=> _sel!=null && st.links(_sel!).contains(it.id),
                      onTapCheck: (it){ if (_sel!=null) setState(()=>st.toggleLink(_sel!, it.id)); },
                      onTapTile: (it){ if (_sel!=null) setState(()=>st.toggleLink(_sel!, it.id)); },
                      checkLeft: true,
                    )),
                  ]);
            return Padding(padding: const EdgeInsets.all(8), child: body);
          },
        ),
      ),
    ]);
  }
}
