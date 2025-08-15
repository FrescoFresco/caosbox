import 'package:flutter/material.dart';

class SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onOpenFilters;
  final List<Widget>? trailing; // por si quieres añadir import/export

  const SearchBar({
    super.key,
    required this.controller,
    this.hint = 'Buscar…',
    this.onChanged,
    this.onOpenFilters,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: hint,
            isDense: true,
            border: const OutlineInputBorder(),
          ),
        ),
      ),
      const SizedBox(width: 8),
      IconButton(
        tooltip: 'Filtros',
        icon: const Icon(Icons.tune),
        onPressed: onOpenFilters,
      ),
      if (trailing != null) ...[
        const SizedBox(width: 4),
        ...trailing!,
      ]
    ]);
  }
}
