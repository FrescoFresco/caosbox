import 'package:flutter/material.dart';
import '../../config/blocks.dart';
import '../../models/enums.dart';
import '../../state/app_state.dart';
import '../../ui/widgets/item_card.dart';
import 'info_modal.dart';

import '../../search/search_models.dart';
import '../../search/search_engine.dart';
import '../../search/search_io.dart';

class GenericScreen extends StatefulWidget {
  final Block block;
  final AppState state;

  // Búsqueda avanzada (bloques)
  final SearchSpec spec;
  // Búsqueda rápida (🔎)
  final String quickQuery;
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
  late final TextEditingController _q;

  @override void initState() {
    super.initState();
    _q = TextEditingController(text: widget.quickQuery);
    _q.addListener(() => widget.onQuickQuery(_q.text));
  }

  @override void didUpdateWidget(covariant GenericScreen old) {
    super.didUpdateWidget(old);
    if (old.quickQuery != widget.quickQuery && _q.text != widget.quickQuery) {
      _q.text = widget.quickQuery;
      _q.selection = TextSelection.collapsed(offset: _q.text.length);
    }
  }

  @override void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override bool get wantKeepAlive => true;

  @override Widget build(BuildContext ctx) {
    super.build(ctx);

    final t = widget.block.type!;
    final src = widget.state.items(t);
    final effective = _mergeQuick(widget.spec, _q.text);
    final filtered = applySearch(widget.state, src, effective);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        // 🔎 + Filtrado avanzado (con JSON dentro)
        Row(children: [
          Expanded(
            child: TextField(
              controller: _q,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar… (usa -palabra para excluir)',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: widget.onOpenFilters,
            icon: const Icon(Icons.tune),
            label: const Text('Filtrado avanzado'),
          ),
        ]),
        const SizedBox(height: 8),

        Expanded(
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final it = filtered[i];
              final open = _ex.contains(it.id);
              return ItemCard(
                item: it,
                st: widget.state,
                ex: open,
                onT: () {
                  open ? _ex.remove(it.id) : _ex.add(it.id);
                  setState(() {});
                },
                onInfo: () => showInfoModal(ctx, it, widget.state),
              );
            },
          ),
        ),
      ]),
    );
  }

  SearchSpec _mergeQuick(SearchSpec base, String q) {
    final parts = q.trim().isEmpty ? <String>[] : q.trim().split(RegExp(r'\s+'));
    final tokens = parts.map((p) {
      if (p.startsWith('-') && p.length > 1) return Token(p.substring(1), Tri.exclude);
      return Token(p, Tri.include);
    }).toList();

    if (tokens.isEmpty) return base;

    final quick = TextClause(
      fields: {'id': Tri.include, 'content': Tri.include, 'note': Tri.include},
      tokens: tokens,
    );
    return SearchSpec(clauses: [...base.clauses, quick]);
  }
}
