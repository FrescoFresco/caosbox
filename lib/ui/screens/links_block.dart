import 'package:flutter/material.dart';
import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/domain/search/search_models.dart';
import 'package:caosbox/ui/widgets/content_block.dart';

/// Enlaces: usa el MISMO modal de filtros avanzados que B1/B2.
/// Le inyectamos el callback [onOpenFilters] y lo reutilizamos en ambas columnas.
class LinksBlock extends StatefulWidget {
  final AppState state;

  /// Callback que abre tu modal de “Búsqueda avanzada” (el mismo de Ideas/Acciones).
  /// Ejemplo de uso al construir:
  ///   onOpenFilters: (ctx) => openAdvancedFilters(ctx),
  final Future<void> Function(BuildContext) onOpenFilters;

  const LinksBlock({
    super.key,
    required this.state,
    required this.onOpenFilters,
  });

  @override
  State<LinksBlock> createState() => _LinksBlockState();
}

class _LinksBlockState extends State<LinksBlock> with AutomaticKeepAliveClientMixin {
  String? _selected;

  // Cada columna mantiene su query rápida y spec (independientes).
  String _leftQuery  = '';
  String _rightQuery = '';
  SearchSpec _leftSpec  = const SearchSpec();
  SearchSpec _rightSpec = const SearchSpec();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final left = Expanded(
      child: ContentBlock(
        key: const ValueKey('links_left'),
        state: widget.state,
        types: null,                    // ambos tipos
        spec: _leftSpec,
        quickQuery: _leftQuery,
        onQuickQuery: (q) => setState(() => _leftQuery = q),
        onOpenFilters: () => widget.onOpenFilters(context), // ← MISMO modal que B1/B2
        showComposer: false,
        mode: ContentBlockMode.select,
        selectedId: _selected,
        onSelect: (id) => setState(() => _selected = id),
        checkboxSide: CheckboxSide.right, // checkbox a la derecha en la columna izq
      ),
    );

    final right = Expanded(
      child: ContentBlock(
        key: ValueKey('links_right_${_selected ?? "none"}'),
        state: widget.state,
        types: null,
        spec: _rightSpec,
        quickQuery: _rightQuery,
        onQuickQuery: (q) => setState(() => _rightQuery = q),
        onOpenFilters: () => widget.onOpenFilters(context), // ← MISMO modal que B1/B2
        showComposer: false,
        mode: ContentBlockMode.link,
        anchorId: _selected,
        checkboxSide: CheckboxSide.left, // checkbox a la izquierda en la columna dcha
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
