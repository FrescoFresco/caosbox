import 'package:flutter/material.dart';
import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/domain/search/search_models.dart';
import 'package:caosbox/ui/widgets/caos_search_bar.dart';
import 'package:caosbox/app.dart' show FiltersSheet;

/// Módulo de buscador unificado:
/// - Campo de búsqueda (lupa, clear)
/// - Botón "tune" que abre la MISMA hoja de "búsqueda avanzada" (FiltersSheet)
/// - Import/Export de datos opcional (para listas principales)
///
/// No decide qué lista se pinta: eso lo hace ContentBlock.
/// Aquí sólo gestionamos quick query y SearchSpec (filtros avanzados).
class UnifiedSearch extends StatefulWidget {
  final AppState state;

  /// Controla el texto de búsqueda rápida.
  final TextEditingController controller;

  /// Especificación de filtros avanzados activa.
  final SearchSpec spec;

  /// Notifica cambios de spec cuando el usuario pulsa "Aplicar" en FiltersSheet.
  final ValueChanged<SearchSpec> onSpecChanged;

  /// Opcionales para Data IO (sólo en listas principales)
  final VoidCallback? onExportData;
  final VoidCallback? onImportData;

  const UnifiedSearch({
    super.key,
    required this.state,
    required this.controller,
    required this.spec,
    required this.onSpecChanged,
    this.onExportData,
    this.onImportData,
  });

  @override
  State<UnifiedSearch> createState() => _UnifiedSearchState();
}

class _UnifiedSearchState extends State<UnifiedSearch> {
  Future<void> _openFilters() async {
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
      onOpenFilters: _openFilters,
      onExportData: widget.onExportData,
      onImportData: widget.onImportData,
    );
  }
}
