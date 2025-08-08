import 'package:caosbox/src/models/models.dart';

/// ░░ Filtros de texto + estado  ░░
enum FilterMode { off, include, exclude }
enum FilterKey  { completed, archived }

class FilterSet {
  final text  = TextEditingController();
  final modes = <FilterKey, FilterMode>{
    FilterKey.completed : FilterMode.off,
    FilterKey.archived  : FilterMode.off,
  };

  void dispose() => text.dispose();
}

/// Helpers internos
bool _pass(FilterMode mode, bool value) => switch (mode) {
      FilterMode.off      => true,
      FilterMode.include  => value,
      FilterMode.exclude  => !value,
    };

class FilterEngine {
  static List<Item> apply(
      List<Item> items,
      AppState    st,
      FilterSet   set,
      ) {
    final q = set.text.text.toLowerCase();
    return items.where((it) {
      final matchesQ = q.isEmpty || it.text.toLowerCase().contains(q);

      return matchesQ &&
          _pass(set.modes[FilterKey.completed]!, it.status == ItemStatus.completed) &&
          _pass(set.modes[FilterKey.archived]!,  it.status == ItemStatus.archived );
    }).toList(growable: false);
  }
}
