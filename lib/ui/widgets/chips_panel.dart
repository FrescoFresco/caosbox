import 'package:flutter/material.dart';
import '../../models/enums.dart';

class FilterSet {
  final text = TextEditingController();
  final modes = {
    FilterKey.completed: FilterMode.off,
    FilterKey.archived:  FilterMode.off,
    FilterKey.hasLinks:  FilterMode.off,
  };

  void dispose() => text.dispose();
  void cycle(FilterKey k) => modes[k] = FilterMode.values[(modes[k]!.index + 1) % 3];
  void clear() { text.clear(); modes.keys.forEach((k) => modes[k] = FilterMode.off); }
  bool get hasActive => text.text.isNotEmpty || modes.values.any((m) => m != FilterMode.off);
}

class ChipsPanel extends StatelessWidget {
  final FilterSet set; final VoidCallback onUpdate;
  const ChipsPanel({super.key, required this.set, required this.onUpdate});

  @override Widget build(BuildContext c) {
    Widget chip(FilterKey k, String lbl) {
      final m = set.modes[k]!, on = m != FilterMode.off;
      final col = on ? (m == FilterMode.include ? Colors.green : Colors.red).withAlpha(50) : null;
      final txt = m == FilterMode.exclude ? '⊘$lbl' : lbl;
      return FilterChip(label: Text(txt), selected: on, selectedColor: col,
          onSelected: (_) { set.cycle(k); onUpdate(); });
    }
    return Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: set.text, onChanged: (_) => onUpdate(),
        decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar...')),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 6, children: [
        chip(FilterKey.completed, '✓'),
        chip(FilterKey.archived,  '↓'),
        chip(FilterKey.hasLinks,  '~'),
        if (set.hasActive)
          IconButton(icon: const Icon(Icons.clear, size: 16),
            onPressed: () { set.clear(); onUpdate(); }),
      ]),
    ]);
  }
}
