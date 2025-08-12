import 'package:flutter/material.dart';
import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/domain/search/search_models.dart';
import 'package:caosbox/ui/widgets/content_block.dart';

// Importa la hoja real de filtros avanzada (misma UI que B1/B2)
import 'package:caosbox/app.dart' show FiltersSheet;

class LinksBlock extends StatefulWidget {
  final AppState state;
  const LinksBlock({super.key, required this.state});

  @override
  State<LinksBlock> createState() => _LinksBlockState();
}

class _LinksBlockState extends State<LinksBlock> with AutomaticKeepAliveClientMixin {
  String? _selected;

  // Cada columna mantiene su búsqueda y spec independientes
  String _leftQuery  = '';
  String _rightQuery = '';
  SearchSpec _leftSpec  = const SearchSpec();
  SearchSpec _rightSpec = const SearchSpec();

  @override
  bool get wantKeepAlive => true;

  // Abre el MISMO modal (FiltersSheet) que B1/B2 para la columna IZQ
  Future<void> _openLeftFilters() async {
    final updated = await showModalBottomSheet<SearchSpec>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FiltersSheet(initial: _leftSpec.clone(), state: widget.state),
    );
    if (updated != null) setState(() => _leftSpec = updated.clone());
  }

  // Abre el MISMO modal (FiltersSheet) que B1/B2 para la columna DCHA
  Future<void> _openRightFilters() async {
    final updated = await showModalBottomSheet<SearchSpec>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FiltersSheet(initial: _rightSpec.clone(), state: widget.state),
    );
    if (updated != null) setState(() => _rightSpec = updated.clone());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final left = Expanded(
      child: ContentBlock(
        key: const ValueKey('links_left'),
        state: widget.state,
        types: null,                     // ambos tipos
        spec: _leftSpec,                 // spec propio columna IZQ
        quickQuery: _leftQuery,
        onQuickQuery: (q) => setState(() => _leftQuery = q),
        onOpenFilters: _openLeftFilters, // ← mismo modal que B1/B2 (FiltersSheet)
        showComposer: false,
        mode: ContentBlockMode.select,
        selectedId: _selected,
        onSelect: (id) => setState(() => _selected = id),
        checkboxSide: CheckboxSide.right, // checkbox a la derecha en columna izq
      ),
    );

    final right = Expanded(
      child: ContentBlock(
        key: ValueKey('links_right_${_selected ?? "none"}'),
        state: widget.state,
        types: null,
        spec: _rightSpec,                // spec propio columna DCHA
        quickQuery: _rightQuery,
        onQuickQuery: (q) => setState(() => _rightQuery = q),
        onOpenFilters: _openRightFilters, // ← mismo modal que B1/B2 (FiltersSheet)
        showComposer: false,
        mode: ContentBlockMode.link,
        anchorId: _selected,
        checkboxSide: CheckboxSide.left, // checkbox a la izquierda en columna dcha
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
