import 'package:flutter/material.dart';

/// Buscador modular: input + botón de filtros.
/// Úsalo así:
///   import 'package:caosbox/ui/widgets/search_bar.dart' as cx;
///   cx.SearchBar(
///     controller: _qRel,                  // tu TextEditingController
///     onChanged: (_) => setState(() {}),  // refrescar lista al teclear
///     onOpenFilters: _openFilters,        // opcional: abre filtros avanzados
///     hint: 'Buscar…',                    // opcional
///   );
class SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onOpenFilters;
  final String hint;

  const SearchBar({
    super.key,
    required this.controller,
    this.onChanged,
    this.onOpenFilters,
    this.hint = 'Buscar…',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: const OutlineInputBorder(),
            ),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.tune),
          tooltip: 'Filtros avanzados',
          onPressed: onOpenFilters,
        ),
      ],
    );
  }
}
