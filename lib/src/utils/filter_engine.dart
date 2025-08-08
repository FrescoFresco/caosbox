import 'package:flutter/material.dart';
import '../models/models.dart' show Item, ItemStatus, AppState;

enum FilterMode { off, include, exclude }
enum FilterKey  { completed, archived, hasLinks }

class FilterSet {
  final text  = TextEditingController();
  final modes = <FilterKey, FilterMode>{
    FilterKey.completed : FilterMode.off,
    FilterKey.archived  : FilterMode.off,
    FilterKey.hasLinks  : FilterMode.off,
  };

  void clear () {
    text.clear();
    for (final k in modes.keys) modes[k] = FilterMode.off;
  }

  void cycle(FilterKey k) =>
      modes[k] = FilterMode.values[(modes[k]!.index + 1) % 3];

  bool get hasActive =>
      text.text.isNotEmpty || modes.values.any((m) => m != FilterMode.off);

  void dispose() => text.dispose();
}

class FilterEngine {
  static bool _pass(FilterMode m, bool v) => switch (m) {
        FilterMode.off     => true,
        FilterMode.include =>  v,
        FilterMode.exclude => !v,
      };

  static List<Item> apply(List<Item> items, AppState st, FilterSet set) {
    final q = set.text.text.toLowerCase();
    final hasQ = q.isNotEmpty;

    return items.where((it) {
      if (hasQ && !'${it.id} ${it.text}'.toLowerCase().contains(q)) return false;
      return _pass(set.modes[FilterKey.completed]!, it.status == ItemStatus.completed) &&
             _pass(set.modes[FilterKey.archived]!,  it.status == ItemStatus.archived ) &&
             _pass(set.modes[FilterKey.hasLinks]!,  st.links(it.id).isNotEmpty       );
    }).toList();
  }
}
