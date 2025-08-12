import 'package:flutter/material.dart';
import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/core/models/enums.dart';
import 'package:caosbox/core/models/item.dart';
import 'package:caosbox/core/utils/tri.dart';

import 'package:caosbox/domain/search/search_models.dart';
import 'package:caosbox/domain/search/search_engine.dart';
import 'package:caosbox/search/search_io.dart';

// buscador unificado propio (no el de Flutter)
import 'package:caosbox/ui/widgets/search_bar.dart' as cx;

import 'package:caosbox/ui/widgets/composer_card.dart';
import 'package:caosbox/ui/screens/info_modal.dart';

enum ContentBlockMode { list, select, link }
enum CheckboxSide { none, left, right }

class ContentBlock extends StatefulWidget {
  final AppState state;

  /// Tipos a mostrar. null = todos (para enlaces y modal)
  final Set<ItemType>? types;

  /// Filtros por pestaña (para Ideas/Acciones). En select/link suele ser vacío.
  final SearchSpec spec;

  /// Búsqueda rápida local del bloque
  final String quickQuery;
  final ValueChanged<String> onQuickQuery;

  /// Abrir filtros avanzados (sólo útil en listas principales)
  final VoidCallback onOpenFilters;

  /// Mostrar el ComposerCard (alta) – sólo en listas principales
  final bool showComposer;

  /// Modo de comportamiento
  final ContentBlockMode mode;

  /// ID ancla para modo link (obligatorio en link)
  final String? anchorId;

  /// Dónde va el checkbox (para select/link)
  final CheckboxSide checkboxSide;

  /// Selección actual (en modo select)
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

        // callbacks IO (sólo en listas principales)
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
        final showFilters  = widget.mode == ContentBlockMode.list;
        final showDataIO   = widget.mode == ContentBlockMode.list;

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            cx.SearchBar(
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
    switch (widget.mode) {
      case ContentBlockMode.list:
        // Lista “lectura/expansión” con Material puro (ExpansionTile)
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, i) {
            final it = items[i];
            final statusIcon = switch (it.status) {
              ItemStatus.completed => const Icon(Icons.check, size: 16, color: Colors.green),
              ItemStatus.archived  => const Icon(Icons.archive, size: 16, color: Colors.grey),
              _ => const SizedBox.shrink(),
            };
            final hasLinks = widget.state.links(it.id).isNotEmpty;

            Widget tile = ExpansionTile(
              key: PageStorageKey('exp_${it.id}'),
              leading: statusIcon,
              title: Row(children: [
                if (hasLinks) const Icon(Icons.link, size: 16, color: Colors.blue),
                if (hasLinks) const SizedBox(width: 6),
                Text(it.id, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
              subtitle: Text(
                it.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(it.text, style: const TextStyle(fontSize: 14)),
                  ),
                ),
              ],
              onLongPress: () => showInfoModal(context, it, widget.state),
            );

            // Swipe opcional con Dismissible → estado (check/archive)
            tile = Dismissible(
              key: Key('sw_${it.id}_${it.status.name}'),
              confirmDismiss: (d) async {
                final s = it.status;
                if (d == DismissDirection.startToEnd) {
                  final next = s == ItemStatus.completed ? ItemStatus.normal : ItemStatus.completed;
                  widget.state.setStatus(it.id, next);
                } else {
                  final next = s == ItemStatus.archived ? ItemStatus.normal : ItemStatus.archived;
                  widget.state.setStatus(it.id, next);
                }
                return false;
              },
              background: _swipeBg(false),
              secondaryBackground: _swipeBg(true),
              child: tile,
            );

            return Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: tile);
          },
        );

      case ContentBlockMode.select:
      case ContentBlockMode.link:
        final anchor = widget.mode == ContentBlockMode.link ? widget.anchorId : null;
        return ListView.builder(
          key: ValueKey('sel_link_${anchor ?? "none"}'),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final it = items[i];
            if (anchor != null && it.id == anchor) return const SizedBox.shrink();

            bool checked = false;
            VoidCallback? onTap;
            Widget? leading, trailing;

            if (widget.mode == ContentBlockMode.select) {
              checked = (widget.selectedId == it.id);
              onTap = () => widget.onSelect?.call(checked ? null : it.id);
              final cb = Checkbox(value: checked, onChanged: (_)=> onTap?.call());
              leading  = widget.checkboxSide == CheckboxSide.left  ? cb : null;
              trailing = widget.checkboxSide == CheckboxSide.right ? cb : null;
            } else {
              checked = anchor != null && widget.state.links(anchor).contains(it.id);
              onTap = () => widget.state.toggleLink(anchor!, it.id);
              final cb = Checkbox(value: checked, onChanged: (_)=> onTap?.call());
              leading  = widget.checkboxSide == CheckboxSide.left  ? cb : null;
              trailing = widget.checkboxSide == CheckboxSide.right ? cb : null;
            }

            return ListTile(
              key: ValueKey('li_${anchor ?? "sel"}_${it.id}'),
              leading: leading,
              trailing: trailing,
              title: Text('${it.id} — ${it.text}', maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: onTap,
            );
          },
        );
    }
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

  Widget _swipeBg(bool secondary) => Container(
    color: (secondary ? Colors.grey : Colors.green).withOpacity(0.15),
    child: Align(
      alignment: secondary ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Icon(secondary ? Icons.archive : Icons.check, color: secondary ? Colors.grey : Colors.green),
      ),
    ),
  );

  void _showLong(BuildContext context, String title, String text) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(title), content: SizedBox(width: 600, child: SelectableText(text)),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar'))],
    ));
  }
}
