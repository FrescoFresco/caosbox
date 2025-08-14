import 'package:flutter/material.dart';
import 'package:caosbox/searchkit/controller.dart';
import 'package:caosbox/searchkit/ui/filters_sheet.dart';

class UnifiedSearchBar extends StatefulWidget {
  final SearchController controller;
  final bool showImportExport;
  const UnifiedSearchBar({super.key, required this.controller, this.showImportExport = true});

  @override
  State<UnifiedSearchBar> createState() => _UnifiedSearchBarState();
}

class _UnifiedSearchBarState extends State<UnifiedSearchBar> {
  late final SearchController c = widget.controller;
  late final TextEditingController _tc = TextEditingController(text: c.quickText);

  @override
  void dispose() { _tc.dispose(); super.dispose(); }

  Future<void> _openAdvanced() async {
    final spec = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => FiltersSheet(controller: c),
    );
    if (spec != null) {
      // FiltersSheet ya llama c.setSpec(), aquí no hace falta nada.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: TextField(
          controller: _tc,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Buscar…',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          onChanged: c.setQuickText,
        ),
      ),
      const SizedBox(width: 8),
      IconButton(
        tooltip: 'Filtros',
        onPressed: _openAdvanced,
        icon: const Icon(Icons.tune),
      ),
    ]);
  }
}
