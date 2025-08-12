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
  final VoidCallback onOpenFilters; // ya no se usa (quedará ignorado)
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

  // Filtros locales (aplicados tras la búsqueda base)
  final Set<ItemType> _ftypes = {};     // vacío = ambos
  Tri _fCompleted = Tri.off;            // off/include/exclude
  Tri _fArchived  = Tri.off;
  Tri _fLinked    = Tri.off;

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

  List<Item> _applyLocalFilters(List<Item> items) {
    Iterable<Item> cur = items;

    // Tipos
    if (_ftypes.isNotEmpty) {
      cur = cur.where((it) => _ftypes.contains(it.type));
    }

    // Completed
    if (_fCompleted == Tri.include) {
      cur = cur.where((it) => it.status == ItemStatus.completed);
    } else if (_fCompleted == Tri.exclude) {
      cur = cur.where((it) => it.status != ItemStatus.completed);
    }

    // Archived
    if (_fArchived == Tri.include) {
      cur = cur.where((it) => it.status == ItemStatus.archived);
    } else if (_fArchived == Tri.exclude) {
      cur = cur.where((it) => it.status != ItemStatus.archived);
    }

    // Linked
    if (_fLinked == Tri.include) {
      cur = cur.where((it) => widget.state.links(it.id).isNotEmpty);
    } else if (_fLinked == Tri.exclude) {
      cur = cur.where((it) => widget.state.links(it.id).isEmpty);
    }

    return List<Item>.from(cur, growable: false);
  }

  void _openFilters() {
    // Hoja simple con chips de tipos y tri-filtros (✓, 📁, 🔗)
    setState((){}); // garantiza rebuild tras cierre si cambian
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      builder: (ctx) {
        Tri cycle(Tri v) => v == Tri.off ? Tri.include : (v == Tri.include ? Tri.exclude : Tri.off);

        Widget triChip(String label, Tri value, VoidCallback onTap, {Color? color}) {
          final bool on = value != Tri.off;
          final Color bg = switch (value) {
            Tri.include => (color ?? Colors.green).withOpacity(0.20),
            Tri.exclude => Colors.red.withOpacity(0.20),
            _ => Colors.transparent,
          };
          final String txt = switch (value) {
            Tri.include => label,
            Tri.exclude => '⊘$label',
            _ => label,
          };
          return ChoiceChip(
            selected: on,
            onSelected: (_) => onTap(),
            label: Text(txt),
            selectedColor: bg,
          );
        }

        Widget typeChip(ItemType t) {
          final on = _ftypes.contains(t);
          return FilterChip(
            selected: on,
            onSelected: (_) => setState(() {
              if (on) { _ftypes.remove(t); } else { _ftypes.add(t); }
            }),
            label: Text(t == ItemType.idea ? 'Ideas' : 'Acciones'),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(runSpacing: 12, spacing: 8, children: [
              const Text('Tipos', style: TextStyle(fontWeight: FontWeight.w600)),
              Row(children: [
                typeChip(ItemType.idea),
                const SizedBox(width: 8),
                typeChip(ItemType.action),
              ]),
              const Divider(),
              const Text('Estado', style: TextStyle(fontWeight: FontWeight.w600)),
              Wrap(spacing: 8, runSpacing: 8, children: [
                triChip('✓', _fCompleted, () => setState(()=> _fCompleted = cycle(_fCompleted)), color: Colors.green),
                triChip('📁', _fArchived,  () => setState(()=> _fArchived  = cycle(_fArchived)),  color: Colors.grey),
                triChip('🔗', _fLinked,    () => setState(()=> _fLinked    = cycle(_fLinked)),    color: Colors.blue),
              ]),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: (){
                  setState(() {
                    _ftypes.clear(); _fCompleted = Tri.off; _fArchived = Tri.off; _fLinked = Tri.off;
                  });
                  Navigator.pop(ctx);
                }, child: const Text('Limpiar')),
                const SizedBox(width: 8),
                FilledButton(onPressed: (){
                  setState((){});
                  Navigator.pop(ctx);
                }, child: const Text('Aplicar')),
              ]),
            ]),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AnimatedBuilder(
      animation: widget.state,
      builder: (_, __) {
        final srcAll    = _sourceByTypes();
        final effective = _mergeQuick(widget.spec, _q.text);
        final baseItems = List<Item>.from(applySearch(widget.state, srcAll, effective), growable: false);
        final items     = _applyLocalFilters(baseItems);

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
        final showDataIO   = widget.mode == ContentBlockMode.list;

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            CaosSearchBar(
              controller: _q,
              onOpenFilters: _openFilters,              // ← siempre el mismo panel interno
              onExportData:  showDataIO ? onExportData : null,
              onImportData:  showDataIO ? onImportData : null,
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
