import 'package:flutter/material.dart';
import '../utils/filter_engine.dart' as engine;

class ChipsPanel extends StatelessWidget {
  final engine.FilterSet set;
  final VoidCallback onUpdate;
  final Map<engine.FilterKey, engine.FilterMode>? defaults;

  const ChipsPanel({
    Key? key,
    required this.set,
    required this.onUpdate,
    this.defaults,
  }) : super(key: key);

  @override
  Widget build(BuildContext ctx) {
    Widget chip(engine.FilterKey k, String label) {
      final m = set.modes[k]!;
      final active = m != engine.FilterMode.off;
      final col = active
          ? (m == engine.FilterMode.include ? Colors.green : Colors.red)
              .withOpacity(0.3)
          : null;
      final txt = m == engine.FilterMode.exclude ? '⊘$label' : label;
      return FilterChip(
        label: Text(txt),
        selected: active,
        selectedColor: col,
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
          onChanged: (_) => onUpdate(),
          decoration: const InputDecoration(
            hintText: 'Buscar...',
            prefixIcon: Icon(Icons.search),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            chip(engine.FilterKey.completed, '✓'),
            chip(engine.FilterKey.archived, '↓'),
            chip(engine.FilterKey.hasLinks, '~'),
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
          ],
        ),
      ],
    );
  }
}
