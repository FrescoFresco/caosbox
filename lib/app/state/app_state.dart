import 'package:flutter/material.dart';
import 'package:caosbox/core/models/enums.dart';
import 'package:caosbox/core/models/item.dart';

class AppState extends ChangeNotifier {
  final Map<ItemType, List<Item>> _items = { ItemType.idea: [], ItemType.action: [] };
  final Map<String, Set<String>> _links = {};
  final Map<ItemType, int> counters = { ItemType.idea: 0, ItemType.action: 0 };
  final Map<String, Item> _cache = {};
  final Map<String, String> _notes = {};

  String note(String id) => _notes[id] ?? '';
  void setNote(String id, String v) { _notes[id] = v; notifyListeners(); }

  List<Item> items(ItemType t) => List.unmodifiable(_items[t]!);
  List<Item> get all => _items.values.expand((e) => e).toList();
  Set<String> links(String id) => _links[id] ?? const <String>{};
  Item? getItem(String id) => _cache[id];

  void add(ItemType t, String text) {
    final v = text.trim(); if (v.isEmpty) return;
    counters[t] = (counters[t] ?? 0) + 1;
    final prefix = t == ItemType.idea ? 'B1' : 'B2';
    final id = '$prefix${counters[t]!.toString().padLeft(3, '0')}';
    _items[t]!.insert(0, Item(id, v, t));
    _reindex(); notifyListeners();
  }

  bool _up(String id, Item Function(Item) ch) {
    final it = _cache[id]; if (it == null) return false;
    final L = _items[it.type]!, i = L.indexWhere((e) => e.id == id); if (i < 0) return false;
    L[i] = ch(it);
    _reindex(); notifyListeners(); return true;
  }

  bool setStatus(String id, ItemStatus s) => _up(id, (it) {
    final chg = (s != it.status);
    return Item(it.id, it.text, it.type,
        status: s,
        createdAt: it.createdAt,
        modifiedAt: chg ? DateTime.now() : it.modifiedAt,
        statusChanges: chg ? it.statusChanges + 1 : it.statusChanges);
  });

  bool updateText(String id, String t) =>
      _up(id, (it) => Item(it.id, t, it.type,
          status: it.status,
          createdAt: it.createdAt,
          modifiedAt: DateTime.now(),
          statusChanges: it.statusChanges));

  void toggleLink(String a, String b) {
    if (a == b || _cache[a] == null || _cache[b] == null) return;
    final sa = _links.putIfAbsent(a, () => <String>{});
    final sb = _links.putIfAbsent(b, () => <String>{});
    if (sa.remove(b)) { sb.remove(a); } else { sa.add(b); sb.add(a); }
    notifyListeners();
  }

  void replaceAll({
    required List<Item> items,
    required Map<ItemType, int> counters,
    Map<String, Set<String>>? links,
    Map<String, String>? notes,
  }) {
    _items[ItemType.idea] = items.where((e) => e.type == ItemType.idea).toList();
    _items[ItemType.action] = items.where((e) => e.type == ItemType.action).toList();
    this.counters[ItemType.idea] = counters[ItemType.idea] ?? 0;
    this.counters[ItemType.action] = counters[ItemType.action] ?? 0;
    _links
      ..clear()
      ..addAll(links ?? {});
    _notes
      ..clear()
      ..addAll(notes ?? {});
    _reindex(); notifyListeners();
  }

  void _reindex() { _cache..clear()..addAll({ for (final it in all) it.id: it }); }
}
