import 'package:flutter/material.dart';

/// Buscador unificado de la app (NO el de Flutter).
/// - Limpieza con ✖️, botón de filtros (opcional),
///   exportar/importar (opcional).
/// - Usa un TextEditingController externo.
class SearchBar extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback? onOpenFilters;   // null => no muestra botón
  final VoidCallback? onExportData;    // null => no muestra botón
  final VoidCallback? onImportData;    // null => no muestra botón

  const SearchBar({
    super.key,
    required this.controller,
    this.hint = 'Buscar… (usa -palabra para excluir)',
    this.onOpenFilters,
    this.onExportData,
    this.onImportData,
  });

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Row(children: [
      Expanded(
        child: TextField(
          controller: c,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            suffixIcon: c.text.isNotEmpty
                ? IconButton(
                    tooltip: 'Limpiar',
                    icon: const Icon(Icons.clear),
                    onPressed: c.clear,
                  )
                : null,
            hintText: widget.hint,
            isDense: true,
            border: const OutlineInputBorder(),
          ),
        ),
      ),
      if (widget.onOpenFilters != null) ...[
        const SizedBox(width: 6),
        IconButton(
          tooltip: 'Filtros',
          onPressed: widget.onOpenFilters,
          icon: const Icon(Icons.tune),
        ),
      ],
      if (widget.onExportData != null) ...[
        const SizedBox(width: 6),
        IconButton(
          tooltip: 'Exportar datos',
          onPressed: widget.onExportData,
          icon: const Icon(Icons.upload),
        ),
      ],
      if (widget.onImportData != null) ...[
        const SizedBox(width: 6),
        IconButton(
          tooltip: 'Importar datos',
          onPressed: widget.onImportData,
          icon: const Icon(Icons.download),
        ),
      ],
    ]);
  }
}
