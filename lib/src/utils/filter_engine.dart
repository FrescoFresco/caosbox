import 'package:flutter/material.dart';
import 'package:caosbox/src/models/models.dart';

/// ──────────────────────────────────────────────────────────
/// DEFINICIONES DE FILTRO
/// ──────────────────────────────────────────────────────────
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

/// ──────────────────────────────────────────────────────────
/// MOTOR DE FILTRADO
/// ──────────────────────────────────────────────────────────
bool _pass(FilterMode m, bool v) => switch (m) {
      FilterMode.off     => true,
      FilterMode.include => v,
      FilterMode.exclude => !v,
    };

class FilterEngine {
  static List<Item> apply(
    List<Item> items,
    AppState    st,       // por si más adelante necesitas estado
    FilterSet   set,
  ) {
    final q = set.text.text.toLowerCase();

    return items.where((it) {
      final okText = q.isEmpty || it.text.toLowerCase().contains(q);
      return okText &&
          _pass(set.modes[FilterKey.completed]!, it.status == ItemStatus.completed) &&
          _pass(set.modes[FilterKey.archived]!,  it.status == ItemStatus.archived );
    }).toList(growable: false);
  }
}
