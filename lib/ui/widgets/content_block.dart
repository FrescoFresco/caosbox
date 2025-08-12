import 'package:flutter/material.dart';
import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/core/models/enums.dart';
import 'package:caosbox/core/models/item.dart';
import 'package:caosbox/core/utils/tri.dart';

import 'package:caosbox/domain/search/search_models.dart';
import 'package:caosbox/domain/search/search_engine.dart';
import 'package:caosbox/search/search_io.dart';

import 'package:caosbox/ui/widgets/caos_search_bar.dart';
import 'package:caosbox/ui/widgets/composer_card.dart';
import 'package:caosbox/ui/screens/info_modal.dart';
import 'package:caosbox/ui/widgets/content_tile.dart';

enum ContentBlockMode { list, select, link }
enum CheckboxSide { none, left, right }

class ContentBlock extends StatefulWidget {
  final AppState state;
  final Set<ItemType>? types;
  final SearchSpec spec;
  final String quickQuery;
  final ValueChanged<String> onQuickQuery;
  final VoidCallback onOpenFilters; // se ocultará según modo
  final bool showComposer;
  final ContentBlockMode mode;
  final String? anchorId;
  final CheckboxSide checkboxSide;
  final String? selectedId;
  final ValueChanged<String?>? onSelect;

  const ContentBlock({
    super.key,
    required this.state,
    this.types,
    required this.spec,
    required this.quickQuery,
    required this.onQuickQuery,
    required this.onOpenFilters,
    this.showComposer = false,
    this.mode = ContentBlockMode.list,
    this.anchorId,
    this.checkboxSide = CheckboxSide.none,
    this.selectedId,
    this.onSelect,
  });

  @override
  State<ContentBlock> createState() => _ContentBlockState();
}

class _ContentBlockState extends State<ContentBlock> with AutomaticKeepAliveClientMixin {
  late final TextEditingController _q;
  late final TextEditingController _composer;

  @override
  void initState() {
    super.initState();
    _q = TextEditingController(text: widget.quickQuery)..addListener(() => widget.onQuickQuery(_q.text));
    _composer = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant ContentBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quickQuery != widget.quickQuery && _q.text != widget.quickQuery) {
      _q.text = widget.quickQuery;
      _q.selection = TextSelection.collapsed(offset: _q.text.length);
    }
  }

  @override
  void dispose() { _q.dispose(); _composer.dispose(); super.dispose(); }
  @override bool get wantKeepAlive => true;

  List<Item> _sourceByTypes() {
    if (widget.types == null) return widget.state.all;
    final out = <Item>[];
    for (final t in widget.types!) { out.addAll(widget.state.items(t)); }
    return out;
  }

  SearchSpec _mergeQuick(SearchSpec base, String q) {
    final parts = q.trim().isEmpty ? <String>[] : q.trim().split(RegExp(r'\s+'));
    final tokens = parts.map((p) => p.startsWith('-') && p.length > 1 ? Token(p.substring(1), Tri.exclude) : Token(p, Tri.include)).toList();
    if (tokens.isEmpty) return base;
    final quick = TextClause(fields: {'id':Tri.include,'content':Tri.include,'note':Tri.include}, tokens: tokens);
    return SearchSpec(clauses: [...base.clauses, quick]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AnimatedBuilder(
      animation: widget.state,
      builder: (_, __) {
        final srcAll    = _sourceByTypes();
        final effective = _mergeQuick(widget.spec, _q.text);
        final items     = List<Item>.from(applySearch(widget.state, srcAll, effective), growable: false);

        final onExportData = () {
          final json = exportDataJson(widget.state);
          _showLong(context, 'Datos (JSON)', json);
        };
        final onImportData = () async {
          final ctrl = TextEditingController();
          final ok = await showDialog<bool>(
            context: context,
            builder: (dctx) => AlertDialog(
              title: const Text('Importar datos (reemplaza)'),
              content: TextField(controller: ctrl, maxLines: 14, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Pega aquí el JSON de datos…')),
              actions: [
                TextButton(onPressed: ()=>Navigator.pop(dctx,false), child: const Text('Cancelar')),
                FilledButton(onPressed: ()=>Navigator.pop(dctx,true), child: const Text('Importar')),
              ],
            ),
          );
          if (ok == true) {
            try { importDataJsonReplace(widget.state, ctrl.text); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Datos importados'))); }
            catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
          }
        };

        final showComposer = widget.showComposer && widget.mode == ContentBlockMode.list;
        // 🔧 AHORA: el botón de filtros SOLO en modo list (Ideas/Acciones)
        final showFilters  = widget.mode == ContentBlockMode.list;
        // IO solo para Ideas/Acciones
        final showDataIO   = widget.mode == ContentBlockMode.list;

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            CaosSearchBar(
              controller: _q,
              onOpenFilters: showFilters ? widget.onOpenFilters : null,
              onExportData:  showDataIO  ? onExportData : null,
              onImportData:  showDataIO  ? onImportData : null,
            ),
            if (showComposer) ...[
              const SizedBox(height: 12),
              ComposerCard(
                icon: _composerIcon(),
                hint: _composerHint(),
                controller: _composer,
                onAdd: () { final t = _singleTypeOrNull(); if (t!=null){ widget.state.add(t, _composer.text); _composer.clear(); } },
                onCancel: () { _composer.clear(); },
              ),
            ],
            const SizedBox(height: 8),
            Expanded(child: _buildList(items)),
          ]),
        );
      },
    );
  }

  Widget _buildList(List<Item> items) {
    final cbSide = switch (widget.checkboxSide) {
      CheckboxSide.left  => TileCheckboxSide.left,
      CheckboxSide.right => TileCheckboxSide.right,
      _ => TileCheckboxSide.none,
    };

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (_, i) {
        final it = items[i];
        if (widget.mode == ContentBlockMode.link && widget.anchorId != null && it.id == widget.anchorId) {
          return const SizedBox.shrink();
        }

        final hasLinks = widget.state.links(it.id).isNotEmpty;
        final Color statusColor = switch (it.status) {
          ItemStatus.completed => Colors.green,
          ItemStatus.archived  => Colors.grey,
          _ => Colors.transparent,
        };
        final IconData typeIcon = it.type == ItemType.idea ? Icons.lightbulb : Icons.assignment;

        bool checked = false;
        VoidCallback? onToggleCheck;

        if (widget.mode == ContentBlockMode.select) {
          checked = (widget.selectedId == it.id);
          onToggleCheck = () => widget.onSelect?.call(checked ? null : it.id);
        } else if (widget.mode == ContentBlockMode.link) {
          final anchor = widget.anchorId;
          checked = anchor != null && widget.state.links(anchor).contains(it.id);
          onToggleCheck = () { if (anchor != null) widget.state.toggleLink(anchor, it.id); };
        }

        Future<void> _swipeStartToEnd() async {
          final s = it.status; final next = s == ItemStatus.completed ? ItemStatus.normal : ItemStatus.completed;
          widget.state.setStatus(it.id, next);
        }
        Future<void> _swipeEndToStart() async {
          final s = it.status; final next = s == ItemStatus.archived ? ItemStatus.normal : ItemStatus.archived;
          widget.state.setStatus(it.id, next);
        }

        return ContentTile(
          key: ValueKey('ct_${widget.mode}_${widget.anchorId ?? "none"}_${it.id}_${it.status.name}'),
          id: it.id,
          text: it.text,
          typeIcon: typeIcon,
          hasLinks: hasLinks,
          statusColor: statusColor,
          checkboxSide: widget.mode == ContentBlockMode.list ? TileCheckboxSide.none : cbSide,
          checked: checked,
          onToggleCheck: onToggleCheck,
          onLongPress: () => showInfoModal(context, it, widget.state),
          onSwipeStartToEnd: _swipeStartToEnd,
          onSwipeEndToStart: _swipeEndToStart,
        );
      },
    );
  }

  String _composerHint() {
    final t = _singleTypeOrNull();
    if (t == ItemType.idea) return 'Escribe tu idea...';
    if (t == ItemType.action) return 'Describe la acción...';
    return 'Añadir...';
  }
  IconData _composerIcon() {
    final t = _singleTypeOrNull();
    if (t == ItemType.idea) return Icons.lightbulb;
    if (t == ItemType.action) return Icons.assignment;
    return Icons.add;
  }
  ItemType? _singleTypeOrNull() {
    final ts = widget.types; if (ts == null || ts.length != 1) return null; return ts.first;
  }

  void _showLong(BuildContext context, String title, String text) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(title), content: SizedBox(width: 600, child: SelectableText(text)),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar'))],
    ));
  }
}
