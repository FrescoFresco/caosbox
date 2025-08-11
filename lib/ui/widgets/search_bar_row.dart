import 'package:flutter/material.dart';

class SearchBarRow extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onOpenFilters;
  final String hint;
  const SearchBarRow({
    super.key,
    required this.controller,
    required this.onOpenFilters,
    this.hint = 'Buscar… (usa -palabra para excluir)',
  });

  @override
  State<SearchBarRow> createState() => _SearchBarRowState();
}

class _SearchBarRowState extends State<SearchBarRow> {
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
      const SizedBox(width: 8),
      OutlinedButton.icon(
        onPressed: widget.onOpenFilters,
        icon: const Icon(Icons.tune),
        label: const Text('Filtrar'),
      ),
    ]);
  }
}
