// lib/src/models/models.dart

import 'dart:async';
import 'package:flutter/material.dart';

/// ===== MODELS & ENUMS =====

enum ItemType { idea, action }
enum ItemStatus { normal, completed, archived }
enum FilterMode { off, include, exclude }
enum FilterKey { completed, archived, hasLinks }

class Item {
  final String id, text;
  final ItemType type;
  final ItemStatus status;
  final DateTime createdAt, modifiedAt;
  final int statusChanges;

  Item(
    this.id,
    this.text,
    this.type, [
    this.status = ItemStatus.normal,
    DateTime? c,
    DateTime? m,
    this.statusChanges = 0,
  ])  : createdAt = c ?? DateTime.now(),
        modifiedAt = m ?? DateTime.now();

  Item copyWith({ItemStatus? status}) {
    final ns = status ?? this.status;
    final chg = ns != this.status;
    return Item(
      id,
      text,
      type,
      ns,
      createdAt,
      chg ? DateTime.now() : modifiedAt,
      chg ? statusChanges + 1 : statusChanges,
    );
  }
}

extension StatusName on ItemStatus {
  String get name => switch (this) {
        ItemStatus.normal => 'Normal',
        ItemStatus.completed => 'Completado ✓',
        ItemStatus.archived => 'Archivado 📁'
      };
}

/// ===== APP STATE =====

class AppState extends ChangeNotifier {
  final Map<ItemType, List<Item>> _items = {
    ItemType.idea: [],
    ItemType.action: []
  };
  final Map<String, Set<String>> _links = {};
  final Map<ItemType, int> _cnt = {
    ItemType.idea: 0,
    ItemType.action: 0
  };
  final Map<String, Item> _cache = {};
  final Map<String, String> _notes = {};

  String note(String id) => _notes[id] ?? '';
  void setNote(String id, String v) {
    _notes[id] = v;
    notifyListeners();
  }

  List<Item> items(ItemType t) => List.unmodifiable(_items[t]!);
  List<Item> get all => _items.values.expand((e) => e).toList();
  Set<String> links(String id) => _links[id] ?? {};
  Item? getItem(String id) => _cache[id];

  void add(ItemType t, String text) {
    final v = text.trim();
    if (v.isEmpty) return;
    _cnt[t] = (_cnt[t] ?? 0) + 1;
    final prefix = t == ItemType.idea ? 'B1' : 'B2';
    final id = '$prefix${_cnt[t]!.toString().padLeft(3, '0')}';
    _items[t]!.insert(0, Item(id, v, t));
    _reindex();
    notifyListeners();
  }

  bool _up(String id, Item Function(Item) ch) {
    final it = _cache[id];
    if (it == null) return false;
    final L = _items[it.type]!;
    final idx = L.indexWhere((e) => e.id == id);
    if (idx < 0) return false;
    L[idx] = ch(it);
    _reindex();
    notifyListeners();
    return true;
  }

  bool setStatus(String id, ItemStatus s) =>
      _up(id, (it) => it.copyWith(status: s));

  bool updateText(String id, String t) =>
      _up(id, (it) => Item(it.id, t, it.type, it.status, it.createdAt,
          DateTime.now(), it.statusChanges));

  void toggleLink(String a, String b) {
    if (a == b || _cache[a] == null || _cache[b] == null) return;
    final sa = _links.putIfAbsent(a, () => <String>{});
    final sb = _links.putIfAbsent(b, () => <String>{});
    if (sa.remove(b)) {
      sb.remove(a);
    } else {
      sa.add(b);
      sb.add(a);
    }
    notifyListeners();
  }

  void _reindex() {
    _cache
      ..clear()
      ..addAll({for (final it in all) it.id: it});
  }
}

/// ===== STYLES & BEHAVIOR =====

class Style {
  static const title = TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
  static const id =
      TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500);
  static const content = TextStyle(fontSize: 14);
  static const info = TextStyle(fontWeight: FontWeight.w600);
  static BoxDecoration get card => BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      );

  static const statusIcons = {
    ItemStatus.completed: {'icon': Icons.check, 'color': Colors.green},
    ItemStatus.archived: {'icon': Icons.archive, 'color': Colors.grey},
  };
}

class Behavior {
  static Future<bool> swipe(
          DismissDirection d, ItemStatus s, void Function(ItemStatus) on) async =>
      on(d == DismissDirection.startToEnd
              ? (s == ItemStatus.completed
                  ? ItemStatus.normal
                  : ItemStatus.completed)
              : (s == ItemStatus.archived
                  ? ItemStatus.normal
                  : ItemStatus.archived)) ==
          null
          ? false
          : false;

  static Widget bg(bool sec) => Container(
        color: (sec ? Colors.grey : Colors.green).withOpacity(0.2),
        child: Align(
          alignment: sec ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Icon(sec ? Icons.archive : Icons.check,
                color: sec ? Colors.grey : Colors.green),
          ),
        ),
      );
}

/// ===== FILTROS =====

class FilterSet {
  final text = TextEditingController();
  final modes = <FilterKey, FilterMode>{
    FilterKey.completed: FilterMode.off,
    FilterKey.archived: FilterMode.off,
    FilterKey.hasLinks: FilterMode.off,
  };

  void dispose() => text.dispose();
  void setDefaults(Map<FilterKey, FilterMode> d) {
    clear();
    d.forEach((k, v) => modes[k] = v);
  }

  void cycle(FilterKey k) =>
      modes[k] = FilterMode.values[(modes[k]!.index + 1) % 3];

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
