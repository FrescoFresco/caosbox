import 'package:flutter/material.dart';
import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/core/models/enums.dart';
import 'package:caosbox/core/utils/tri.dart';
import 'package:caosbox/domain/search/search_models.dart';
import 'package:caosbox/ui/widgets/content_block.dart';

class LinksBlock extends StatefulWidget {
  final AppState state;
  const LinksBlock({super.key, required this.state});

  @override
  State<LinksBlock> createState() => _LinksBlockState();
}

class _LinksBlockState extends State<LinksBlock> with AutomaticKeepAliveClientMixin {
  String? _selected;

  // Búsqueda/filtrado independientes por columna
  String _leftQuery  = '';
  String _rightQuery = '';
  SearchSpec _leftSpec  = const SearchSpec();
  SearchSpec _rightSpec = const SearchSpec();

  LocalFilters _leftFilters  = LocalFilters.empty;
  LocalFilters _rightFilters = LocalFilters.empty;

  @override bool get wantKeepAlive => true;

  // === Hoja de filtros avanzada (reutilizada por ambas columnas) ===
  Future<LocalFilters?> _openFilters(BuildContext ctx, LocalFilters cur) async {
    LocalFilters tmp = cur;
    Tri cycle(Tri v) => v == Tri.off ? Tri.include : (v == Tri.include ? Tri.exclude : Tri.off);

    return showModalBottomSheet<LocalFilters>(
      context: ctx,
      isScrollControlled: false,
      builder: (_) => StatefulBuilder(
        builder: (c, setS) {
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

          FilterChip typeChip(ItemType t) {
            final on = tmp.types.contains(t);
            return FilterChip(
              selected: on,
              onSelected: (_) => setS(() {
                final ns = Set<ItemType>.from(tmp.types);
                if (on) { ns.remove(t); } else { ns.add(t); }
                tmp = tmp.copyWith(types: ns);
              }),
              label: Text(t == ItemType.idea ? 'Ideas' : 'Acciones'),
            );
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Tipos', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  typeChip(ItemType.idea),
                  typeChip(ItemType.action),
                ]),
                const Divider(height: 24),
                const Text('Estado', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  triChip('✓', tmp.completed, () => setS(()=> tmp = tmp.copyWith(completed: cycle(tmp.completed))), color: Colors.green),
                  triChip('📁', tmp.archived,  () => setS(()=> tmp = tmp.copyWith(archived:  cycle(tmp.archived))),  color: Colors.grey),
                  triChip('🔗', tmp.linked,    () => setS(()=> tmp = tmp.copyWith(linked:    cycle(tmp.linked))),    color: Colors.blue),
                ]),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton(onPressed: (){
                    setS((){ tmp = LocalFilters.empty; });
                  }, child: const Text('Limpiar')),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: (){
                    Navigator.pop(c, tmp);
                  }, child: const Text('Aplicar')),
                ]),
              ]),
            ),
          );
        },
      ),
    );
  }

  void _openLeftFilters() async {
    final res = await _openFilters(context, _leftFilters);
    if (res != null) setState(() => _leftFilters = res);
  }

  void _openRightFilters() async {
    final res = await _openFilters(context, _rightFilters);
    if (res != null) setState(() => _rightFilters = res);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final left = Expanded(
      child: ContentBlock(
        key: const ValueKey('links_left'),
        state: widget.state,
        types: null,                         // ambos
        spec: _leftSpec,                     // espec. de búsqueda (si la usas)
        quickQuery: _leftQuery,              // query rápida (independiente)
        onQuickQuery: (q)=> setState(()=> _leftQuery = q),
        onOpenFilters: _openLeftFilters,     // ← abre filtros avanzados de la COLUMNA IZQ
        localFilters: _leftFilters,          // ← se aplican localmente
        showComposer: false,
        mode: ContentBlockMode.select,
        selectedId: _selected,
        onSelect: (id)=> setState(()=> _selected = id),
        checkboxSide: CheckboxSide.right,    // checkbox a la DERECHA en izq (ancla)
      ),
    );

    final right = Expanded(
      child: ContentBlock(
        key: ValueKey('links_right_${_selected ?? "none"}'),
        state: widget.state,
        types: null,
        spec: _rightSpec,
        quickQuery: _rightQuery,
        onQuickQuery: (q)=> setState(()=> _rightQuery = q),
        onOpenFilters: _openRightFilters,    // ← abre filtros avanzados de la COLUMNA DCHA
        localFilters: _rightFilters,         // ← se aplican localmente
        showComposer: false,
        mode: ContentBlockMode.link,
        anchorId: _selected,
        checkboxSide: CheckboxSide.left,     // checkbox a la IZQUIERDA en dcha (link)
      ),
    );

    return SafeArea(
      child: Column(children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Conectar elementos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: OrientationBuilder(
            builder: (ctx, o) => o == Orientation.portrait
                ? Column(children: [left, const Divider(height: 1), right])
                : Row(children: [left, const VerticalDivider(width: 1), right]),
          ),
        ),
      ]),
    );
  }
}
