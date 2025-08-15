import 'package:flutter/material.dart';
import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/core/models/item.dart';
import 'package:caosbox/core/models/enums.dart';
import 'package:caosbox/core/models/filters.dart';

class FilterSet {
  final text = TextEditingController();
  final Map<FilterKey, FilterMode> modes = {
    FilterKey.completed: FilterMode.off,
    FilterKey.archived: FilterMode.off,
    FilterKey.hasLinks: FilterMode.off,
  };

  void dispose() => text.dispose();

  void setDefaults(Map<FilterKey, FilterMode> d) {
    clear();
    d.forEach((k, v) => modes[k] = v);
  }

  void cycle(FilterKey k) {
    modes[k] = FilterMode.values[(modes[k]!.index + 1) % 3];
  }

  void clear() {
    text.clear();
    for (final k in modes.keys) {
      modes[k] = FilterMode.off;
    }
  }

  bool get hasActive =>
      text.text.isNotEmpty || modes.values.any((m) => m != FilterMode.off);
}

class FilterEngine {
  static bool _pass(FilterMode m, bool v) => switch (m) {
        FilterMode.off => true,
        FilterMode.include => v,
        FilterMode.exclude => !v,
      };

  static List<Item> apply(List<Item> items, AppState s, FilterSet set) {
    final q = set.text.text.toLowerCase();
    final hasQ = q.isNotEmpty;
    return items.where((it) {
      if (hasQ) {
        final a = '${it.id} ${it.text} ${s.note(it.id)}'.toLowerCase();
        if (!a.contains(q)) return false;
      }
      return _pass(set.modes[FilterKey.completed]!, it.status == ItemStatus.completed) &&
          _pass(set.modes[FilterKey.archived]!, it.status == ItemStatus.archived) &&
          _pass(set.modes[FilterKey.hasLinks]!, s.links(it.id).isNotEmpty);
    }).toList();
  }
}

class ChipsPanel extends StatelessWidget {
  final FilterSet set;
  final VoidCallback onUpdate;
  final Map<FilterKey, FilterMode>? defaults;
  const ChipsPanel({super.key, required this.set, required this.onUpdate, this.defaults});

  @override
  Widget build(BuildContext ctx) {
    Widget chip(FilterKey k, String label) {
      final m = set.modes[k]!;
      final on = m != FilterMode.off;
      final col = on ? (m == FilterMode.include ? Colors.green : Colors.red).withValues(alpha: 0.3) : null;
      final txt = m == FilterMode.exclude ? '⊘$label' : label;
      return FilterChip(
        label: Text(txt),
        selected: on,
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
          ],
        ),
      ],
    );
  }
}
