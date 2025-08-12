import 'package:flutter/material.dart';

/// Buscador unificado (el de antes):
/// - Lupa + campo
/// - Botón de filtros (si onOpenFilters != null)
/// - Exportar/Importar datos (si se pasan)
class CaosSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback? onOpenFilters;
  final VoidCallback? onExportData;
  final VoidCallback? onImportData;

  const CaosSearchBar({
    super.key,
    required this.controller,
    this.hint = 'Buscar… (usa -palabra para excluir)',
    this.onOpenFilters,
    this.onExportData,
    this.onImportData,
  });

  @override
  State<CaosSearchBar> createState() => _CaosSearchBarState();
}

class _CaosSearchBarState extends State<CaosSearchBar> {
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
                ? IconButton(icon: const Icon(Icons.clear), onPressed: c.clear)
                : null,
            hintText: widget.hint,
            isDense: true,
            border: const OutlineInputBorder(),
          ),
        ),
      ),
      if (widget.onOpenFilters != null) ...[
        const SizedBox(width: 6),
        IconButton(onPressed: widget.onOpenFilters, icon: const Icon(Icons.tune)),
      ],
      if (widget.onExportData != null) ...[
        const SizedBox(width: 6),
        IconButton(onPressed: widget.onExportData, icon: const Icon(Icons.upload)),
      ],
      if (widget.onImportData != null) ...[
        const SizedBox(width: 6),
        IconButton(onPressed: widget.onImportData, icon: const Icon(Icons.download)),
      ],
    ]);
  }
}
