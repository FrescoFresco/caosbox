import 'package:flutter/material.dart';

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
          tooltip: 'Filtros',
          onPressed: onOpenFilters,
        ),
      ],
    );
  }
}
