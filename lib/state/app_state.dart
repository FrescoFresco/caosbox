import 'package:flutter/foundation.dart';
import '../models/enums.dart';
import '../models/item.dart';
import '../config/blocks.dart';

class AppState extends ChangeNotifier {
  final Map<ItemType, List<Item>> _items = {
    ItemType.idea: <Item>[],
    ItemType.action: <Item>[],
  };

  final Map<String, Set<String>> _links = {};  // id -> {ids}
  final Map<ItemType, int> _cnt = {ItemType.idea: 0, ItemType.action: 0};
  final Map<String, Item> _cache = {};
  final Map<String, String> _notes = {}; // nota "tiempo"

  List<Item> items(ItemType t) => List.unmodifiable(_items[t]!);
  List<Item> get all => _items.values.expand((e) => e).toList();

  Set<String> links(String id) => _links[id] ?? const <String>{};
  String note(String id) => _notes[id] ?? '';
  Item? getItem(String id) => _cache[id];

  void add(ItemType t, String text) {
    final v = text.trim();
    if (v.isEmpty) return;
    _cnt[t] = (_cnt[t] ?? 0) + 1;
    final cfg = t == ItemType.idea ? ideasCfg : actionsCfg;
    final id = '${cfg.prefix}${_cnt[t]!.toString().padLeft(3, '0')}';
    final it = Item(id, v, t);
    _items[t]!.insert(0, it);
    _cache[id] = it;
    notifyListeners();
  }

  bool setStatus(String id, ItemStatus s) => _update(id, (it) {
    final ns = it.status == s ? it.status : s;
    final chg = ns != it.status;
    return it.copyWith(
      status: ns,
      modifiedAt: chg ? DateTime.now() : it.modifiedAt,
      statusChanges: chg ? it.statusChanges + 1 : it.statusChanges,
    );
  });

  bool updateText(String id, String txt) => _update(id, (it) => it.copyWith(text: txt, modifiedAt: DateTime.now()));

  void setNote(String id, String v) { _notes[id] = v; notifyListeners(); }

  void toggleLink(String a, String b) {
    if (a == b || _cache[a] == null || _cache[b] == null) return;
    final sa = _links.putIfAbsent(a, () => <String>{});
    final sb = _links.putIfAbsent(b, () => <String>{});
    if (sa.remove(b)) {
      sb.remove(a);
      if (sa.isEmpty) _links.remove(a);
      if (sb.isEmpty) _links.remove(b);
    } else {
      sa.add(b);
      sb.add(a);
    }
    notifyListeners();
  }

  bool _update(String id, Item Function(Item) cb) {
    final it = _cache[id];
    if (it == null) return false;
    final L = _items[it.type]!;
    final i = L.indexWhere((e) => e.id == id);
    if (i < 0) return false;
    final ni = cb(it);
    L[i] = ni;
    _cache[id] = ni;
    notifyListeners();
    return true;
  }

  void replaceAll({
    required List<Item> items,
    required Map<ItemType, int> counters,
    required Map<String, String> notes,
    required Map<String, Set<String>> links,
  }) {
    _items[ItemType.idea] = <Item>[];
    _items[ItemType.action] = <Item>[];
    _cache.clear();

    for (final it in items) {
      _items[it.type]!.add(it);
      _cache[it.id] = it;
    }

    _cnt
      ..clear()
      ..addAll({ItemType.idea: counters[ItemType.idea] ?? 0, ItemType.action: counters[ItemType.action] ?? 0});

    _notes
      ..clear()
      ..addAll(notes);

    _links
      ..clear()
      ..addAll(links);

    notifyListeners();
  }
}
