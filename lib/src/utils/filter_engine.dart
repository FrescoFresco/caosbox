// lib/src/utils/filter_engine.dart
import '../models/app_state.dart';
import '../models/item.dart';

enum FilterMode { off, include, exclude }
enum FilterKey { completed, archived, hasLinks }

class FilterSet {
  final text = TextEditingController();
  final Map<FilterKey, FilterMode> modes = {
    FilterKey.completed: FilterMode.off,
    FilterKey.archived: FilterMode.off,
    FilterKey.hasLinks: FilterMode.off
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
    for (final k in modes.keys) modes[k] = FilterMode.off;
  }

  bool get hasActive =>
      text.text.isNotEmpty || modes.values.any((m) => m != FilterMode.off);
}

class FilterEngine {
  static bool _pass(FilterMode m, bool v) => switch (m) {
        FilterMode.off => true,
        FilterMode.include => v,
        FilterMode.exclude => !v
      };

  static List<Item> apply(
      List<Item> items, AppState s, FilterSet set) {
    final q = set.text.text.toLowerCase();
    final hasQ = q.isNotEmpty;
    return items.where((it) {
      if (hasQ && !'${it.id} ${it.text}'.toLowerCase().contains(q)) {
        return false;
      }
      return _pass(set.modes[FilterKey.completed]!, it.status == ItemStatus.completed) &&
          _pass(set.modes[FilterKey.archived]!, it.status == ItemStatus.archived) &&
          _pass(set.modes[FilterKey.hasLinks]!, s.links(it.id).isNotEmpty);
    }).toList();
  }
}
