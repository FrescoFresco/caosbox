// lib/src/widgets/chips_panel.dart

import 'package:flutter/material.dart';
import '../models/models.dart';
import '../../main.dart'; // para AppState
import '../utils/filter_engine.dart';

class ChipsPanel extends StatelessWidget {
  final FilterSet set;
  final VoidCallback onUpdate;
  final Map<FilterKey, FilterMode>? defaults;

  const ChipsPanel({
    super.key,
    required this.set,
    required this.onUpdate,
    this.defaults,
  });

  @override
  Widget build(BuildContext ctx) {
    Widget chip(FilterKey key, String label) {
      final mode = set.modes[key]!;
      final active = mode != FilterMode.off;
      final color = active
          ? (mode == FilterMode.include ? Colors.green : Colors.red)
              .withOpacity(0.3)
          : null;
      final text = mode == FilterMode.exclude ? '⊘$label' : label;

      return FilterChip(
        label: Text(text),
        selected: active,
        selectedColor: color,
        onSelected: (_) {
          set.cycle(key);
          onUpdate();
        },
      );
    }

    return Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(
        controller: set.text,
        onChanged: (_) => onUpdate(),
        decoration: const InputDecoration(
          hintText: 'Buscar…',
          prefixIcon: Icon(Icons.search),
          isDense: true,
        ),
      ),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 6, children: [
        chip(FilterKey.completed, '✓'),
        chip(FilterKey.archived, '↓'),
        chip(FilterKey.hasLinks, '~'),
        if (set.hasActive)
          IconButton(
            icon: const Icon(Icons.clear, size: 16),
            onPressed: () {
              if (defaults != null) {
                set.setDefaults(defaults!);
              } else {
                set.clear();
              }
              onUpdate();
            },
          ),
      ]),
    ]);
  }
}
