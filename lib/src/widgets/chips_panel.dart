import 'package:flutter/material.dart';
import '../models/models.dart' as models;

class ChipsPanel extends StatelessWidget {
  final models.FilterSet set;
  final VoidCallback onUpdate;
  const ChipsPanel({super.key, required this.set, required this.onUpdate});

  @override Widget build(BuildContext ctx) {
    chip(models.FilterKey k, String label) {
      final m   = set.modes[k]!;
      final sel = m != models.FilterMode.off;
      return FilterChip(
        label: Text(label),
        selected: sel,
        onSelected: (_) {
          set.modes[k] = models.FilterMode.values[(m.index+1)%3];
          onUpdate();
        });
    }

    return Column(children: [
      TextField(controller: set.text, decoration: const InputDecoration(prefixIcon: Icon(Icons.search))),
      Wrap(spacing: 8, children: [
        chip(models.FilterKey.completed,'✓'),
        chip(models.FilterKey.archived,'↓'),
        chip(models.FilterKey.hasLinks,'~'),
      ])
    ]);
  }
}
