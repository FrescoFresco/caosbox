import 'package:flutter/material.dart';
import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/domain/search/search_models.dart';
import 'package:caosbox/ui/widgets/caos_search_bar.dart';
import 'package:caosbox/app.dart' show FiltersSheet;

/// Buscador unificado:
/// - Campo de búsqueda (lupa, clear)
/// - Botón "tune" que abre la MISMA hoja de "búsqueda avanzada"
/// - Import/Export de datos opcional
class UnifiedSearch extends StatefulWidget {
  final AppState state;

  /// Control del texto de búsqueda rápida.
  final TextEditingController controller;

  /// Especificación de filtros avanzados activa.
  final SearchSpec spec;

  /// Notifica cambios de spec cuando el usuario pulsa "Aplicar".
  final ValueChanged<SearchSpec> onSpecChanged;

  /// Si se provee, se usará este callback para abrir el modal (en vez de FiltersSheet interno).
  final VoidCallback? openFilters;

  /// Opcionales para Data IO (sólo en listas principales)
  final VoidCallback? onExportData;
  final VoidCallback? onImportData;

  const UnifiedSearch({
    super.key,
    required this.state,
    required this.controller,
    required this.spec,
    required this.onSpecChanged,
    this.openFilters,
    this.onExportData,
    this.onImportData,
  });

  @override
  State<UnifiedSearch> createState() => _UnifiedSearchState();
}

class _UnifiedSearchState extends State<UnifiedSearch> {
  Future<void> _openFiltersInternal() async {
    final updated = await showModalBottomSheet<SearchSpec>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FiltersSheet(initial: widget.spec.clone(), state: widget.state),
    );
    if (updated != null) widget.onSpecChanged(updated.clone());
  }

  @override
  Widget build(BuildContext context) {
    return CaosSearchBar(
      controller: widget.controller,
      onOpenFilters: widget.openFilters ?? _openFiltersInternal,
      onExportData: widget.onExportData,
      onImportData: widget.onImportData,
    );
  }
}
