import 'package:flutter/material.dart';
import '../../config/blocks.dart';
import '../../state/app_state.dart';
import '../widgets/item_tile.dart';
import 'info_modal.dart';

import '../../search/search_models.dart';
import '../../search/search_engine.dart';
import '../widgets/search_bar_row.dart';

class GenericScreen extends StatefulWidget {
  final Block block;
  final AppState state;
  final SearchSpec spec;                 // filtros avanzados
  final String quickQuery;               // texto de la lupa
  final ValueChanged<String> onQuickQuery;
  final Future<void> Function(BuildContext) onOpenFilters;

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
  late final TextEditingController _q;

  @override
  void initState() {
    super.initState();
    _q = TextEditingController(text: widget.quickQuery);
    _q.addListener(() => widget.onQuickQuery(_q.text));
  }

  @override
  void didUpdateWidget(covariant GenericScreen old) {
    super.didUpdateWidget(old);
    if (old.quickQuery != widget.quickQuery && _q.text != widget.quickQuery) {
      _q.text = widget.quickQuery;
      _q.selection = TextSelection.collapsed(offset: _q.text.length);
    }
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext ctx) {
    super.build(ctx);
    final t = widget.block.type!;
    final src = widget.state.items(t);

    final effective = _mergeQuick(widget.spec, _q.text);
    final filtered  = applySearch(widget.state, src, effective);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        SearchBarRow(
          controller: _q,
          onOpenFilters: () => widget.onOpenFilters(ctx),
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

  // Combina filtros avanzados + búsqueda rápida (tokens; -palabra = exclude)
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
