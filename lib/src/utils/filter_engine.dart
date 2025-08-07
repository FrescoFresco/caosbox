import 'package:flutter/material.dart';
import '../models/models.dart';

enum FilterMode { off, include, exclude }
enum FilterKey { completed, archived }

class FilterSet {
  final text = TextEditingController();
  final modes = {
    FilterKey.completed: FilterMode.off,
    FilterKey.archived: FilterMode.off
  };
  void dispose() => text.dispose();

  void cycle(FilterKey k) =>
      modes[k] = FilterMode.values[(modes[k]!.index + 1) % 3];
}

class FilterEngine {
  static bool _pass(FilterMode m, bool v) => switch (m) {
        FilterMode.off => true,
        FilterMode.include => v,
        FilterMode.exclude => !v
      };

  static List<Item> apply(List<Item> src, AppState st, FilterSet set) {
    final q = set.text.text.toLowerCase();
    return [
      for (final it in src)
        if ((q.isEmpty ||
                '${it.id} ${it.text}'.toLowerCase().contains(q)) &&
            _pass(set.modes[FilterKey.completed]!,
                it.status == ItemStatus.completed) &&
            _pass(set.modes[FilterKey.archived]!,
                it.status == ItemStatus.archived))
          it
    ];
  }
}
