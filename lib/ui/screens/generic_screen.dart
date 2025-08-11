import 'package:flutter/material.dart';
import 'package:caosbox/core/models/enums.dart';
import 'package:caosbox/core/models/item.dart';
import 'package:caosbox/config/blocks.dart';
import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/ui/widgets/item_tile.dart';
import 'package:caosbox/ui/screens/info_modal.dart';

import 'package:caosbox/domain/search/search_models.dart';
import 'package:caosbox/domain/search/search_engine.dart';
import 'package:caosbox/search/search_io.dart';
import 'package:caosbox/ui/widgets/search_bar_row.dart';

class GenericScreen extends StatefulWidget {
  final Block block;
  final AppState state;
  final SearchSpec spec;
  final String quickQuery;
  final ValueChanged<String> onQuickQuery;
  final Future<void> Function(BuildContext, ItemType) onOpenFilters;

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
  void dispose() { _q.dispose(); super.dispose(); }

  @override bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext ctx) {
    super.build(ctx);
    return AnimatedBuilder(
      animation: widget.state,
      builder: (_, __) {
        final t = widget.block.type!;
        final src = widget.state.items(t);
        final effective = _mergeQuick(widget.spec, _q.text);

        final filtered = List<Item>.from(applySearch(widget.state, src, effective), growable: false);

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            SearchBarRow(
              controller: _q,
              onOpenFilters: () => widget.onOpenFilters(ctx, t),
              onExportData: () { final json = exportDataJson(widget.state); _showLong(ctx, 'Datos (JSON)', json); },
              onImportData: () async {
                final ctrl = TextEditingController();
                final ok = await showDialog<bool>(
                  context: ctx,
                  builder: (dctx) => AlertDialog(
                    title: const Text('Importar datos (reemplaza)'),
                    content: TextField(controller: ctrl, maxLines: 14, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Pega aquí el JSON de datos…')),
                    actions: [ TextButton(onPressed: ()=>Navigator.pop(dctx,false), child: const Text('Cancelar')),
                               FilledButton(onPressed: ()=>Navigator.pop(dctx,true), child: const Text('Importar')) ],
                  ),
                );
                if (ok == true) {
                  try { importDataJsonReplace(widget.state, ctrl.text); if (mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Datos importados'))); }
                  catch (e) { if (mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'))); }
                }
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                key: PageStorageKey('list_${t.name}'),
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final it = filtered[i];
                  final open = _ex.contains(it.id);
                  return KeyedSubtree(
                    key: ValueKey(it.id),
                    child: ItemTile(
                      key: ValueKey('tile_${it.id}'),
                      item: it,
                      st: widget.state,
                      expanded: open,
                      onTap: () { open ? _ex.remove(it.id) : _ex.add(it.id); setState((){}); },
                      onInfo: () => showInfoModal(ctx, it, widget.state),
                      swipeable: true,
                      checkbox: false,
                    ),
                  );
                },
              ),
            ),
          ]),
        );
      },
    );
  }

  void _showLong(BuildContext context, String title, String text) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(title), content: SizedBox(width: 600, child: SelectableText(text)),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar'))],
    ));
  }

  SearchSpec _mergeQuick(SearchSpec base, String q) {
    final parts = q.trim().isEmpty ? <String>[] : q.trim().split(RegExp(r'\s+'));
    final tokens = parts.map((p) => p.startsWith('-') && p.length > 1 ? Token(p.substring(1), Tri.exclude) : Token(p, Tri.include)).toList();
    if (tokens.isEmpty) return base;
    final quick = TextClause(fields: {'id':Tri.include,'content':Tri.include,'note':Tri.include}, tokens: tokens);
    return SearchSpec(clauses: [...base.clauses, quick]);
  }
}
