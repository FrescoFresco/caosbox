import 'package:flutter/material.dart';
import '../utils/filter_engine.dart';   // ← aquí viene el FilterSet bueno

class ChipsPanel extends StatelessWidget {
  final FilterSet set;
  final VoidCallback onUpdate;
  const ChipsPanel({
    super.key,
    required this.set,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    Chip buildChip(FilterKey k, String label) {
      final mode   = set.modes[k]!;
      final active = mode != FilterMode.off;
      final bg     = active
          ? (mode == FilterMode.include ? Colors.green : Colors.red).withOpacity(0.25)
          : null;
      final text   = mode == FilterMode.exclude ? '⊘$label' : label;

      return FilterChip(
        label: Text(text),
        selected: active,
        selectedColor: bg,
        onSelected: (_) {
          set.cycle(k);
          onUpdate();
        },
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: set.text,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Buscar…',
            isDense: true,
          ),
          onChanged: (_) => onUpdate(),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            buildChip(FilterKey.completed, '✓'),
            buildChip(FilterKey.archived,  '↓'),
            buildChip(FilterKey.hasLinks,  '~'),
            if (set.hasActive)
              IconButton(
                icon: const Icon(Icons.clear, size: 16),
                onPressed: () { set.clear(); onUpdate(); },
              ),
          ],
        ),
      ],
    );
  }
}
