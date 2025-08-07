import 'package:flutter/material.dart';
import '../utils/filter_engine.dart' as utils;

class ChipsPanel extends StatelessWidget {
  const ChipsPanel({super.key, required this.set, required this.onUpdate});
  final utils.FilterSet set;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    Widget chip(utils.FilterKey k, String label) {
      final mode = set.modes[k]!;
      final active = mode != utils.FilterMode.off;
      final color = !active
          ? null
          : (mode == utils.FilterMode.include ? Colors.green : Colors.red)
              .withOpacity(.2);
      final text = mode == utils.FilterMode.exclude ? '⊘$label' : label;

      return FilterChip(
        label: Text(text),
        selected: active,
        selectedColor: color,
        onSelected: (_) {
          set.cycle(k);
          onUpdate();
        },
      );
    }

    return Column(children: [
      TextField(
        controller: set.text,
        decoration:
            const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Filtrar…'),
        onChanged: (_) => onUpdate(),
      ),
      Wrap(spacing: 8, children: [
        chip(utils.FilterKey.completed, '✓'),
        chip(utils.FilterKey.archived, '↓'),
      ])
    ]);
  }
}
