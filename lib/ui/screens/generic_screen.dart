import 'package:flutter/material.dart';
import '../../config/blocks.dart';
import '../../state/app_state.dart';
import '../widgets/item_tile.dart';
import 'info_modal.dart';

import '../../search/search_models.dart';
import '../../search/search_engine.dart';

class GenericScreen extends StatefulWidget {
  final Block block;
  final AppState state;
  final SearchSpec spec;                 // filtros avanzados
  final String quickQuery;               // texto de la lupa
  final ValueChanged<String> onQuickQuery;
  final Future<void> Function() onOpenFilters;

  const GenericScreen({
    super.key,
    required this.block,
    required this.state,
    required this.spec,
    required this.quickQuery,
    required this.onQuickQuery,
    required this.onOpenFilters,
  });

  @override State<GenericScreen> createState() => _GenericScreenState();
}

class _GenericScreenState extends State<GenericScreen> with AutomaticKeepAliveClientMixin {
  final _ex = <String>{};
  late final SearchController _sc; // M3 nativo

  @override
  void initState() {
    super.initState();
    _sc = SearchController();                // <-- ctor sin 'text'
    _sc.text = widget.quickQuery;            // <-- set explícito
    _sc.addListener(() => widget.onQuickQuery(_sc.text));
  }

  @override
  void didUpdateWidget(covariant GenericScreen old) {
    super.didUpdateWidget(old);
    if (old.quickQuery != widget.quickQuery && _sc.text != widget.quickQuery) {
      _sc.text = widget.quickQuery;
      _sc.selection = TextSelection.collapsed(offset: _sc.text.length);
    }
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  @override bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext ctx) {
    super.build(ctx);
    final t = widget.block.type!;
    final src = widget.state.items(t);

    final effective = _mergeQuick(widget.spec, _sc.text);
    final filtered  = applySearch(widget.state, src, effective);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        // 🔎 SearchAnchor.bar nativo
        SearchAnchor.bar(
          searchController: _sc,
          barHintText: 'Buscar… (usa -palabra para excluir)',
          barLeading: const Icon(Icons.search),
          barTrailing: [
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: 'Filtrado avanzado',
              onPressed: () => widget.onOpenFilters(),
            ),
          ],
          suggestionsBuilder: (context, controller) {
            final quick = controller.text;
            final spec = _mergeQuick(widget.spec, quick);
            final results = applySearch(widget.state, src, spec).take(6).toList();

            return results.map((it) => ListTile(
              leading: const Icon(Icons.history),
              title: Text(it.text, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(it.id),
              onTap: () {
                controller.text = it.id;
                widget.onQuickQuery(controller.text);
                controller.closeView(it.id);
              },
            ));
          },
        ),
        const SizedBox(height: 8),

        Expanded(
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final it = filtered[i];
              final open = _ex.contains(it.id);
              return ItemTile(
                item: it,
                st: widget.state,
                expanded: open,
                onTap: () { open ? _ex.remove(it.id) : _ex.add(it.id); setState((){}); },
                onInfo: () => showInfoModal(ctx, it, widget.state),
                swipeable: true,
                checkbox: false,
              );
            },
          ),
        ),
      ]),
    );
  }

  // Combina filtros avanzados + 🔎 rápida (tokens; -palabra = exclude)
  SearchSpec _mergeQuick(SearchSpec base, String q) {
    final parts = q.trim().isEmpty ? <String>[] : q.trim().split(RegExp(r'\s+'));
    final tokens = parts.map((p) {
      if (p.startsWith('-') && p.length > 1) return Token(p.substring(1), Tri.exclude);
      return Token(p, Tri.include);
    }).toList();
    if (tokens.isEmpty) return base;
    final quick = TextClause(fields: {'id':Tri.include,'content':Tri.include,'note':Tri.include}, tokens: tokens);
    return SearchSpec(clauses: [...base.clauses, quick]);
  }
}
