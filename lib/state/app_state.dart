import 'package:flutter/foundation.dart';
import '../models/enums.dart';
import '../models/item.dart';
import '../config/blocks.dart';

class AppState extends ChangeNotifier {
  // listas por tipo
  final Map<ItemType, List<Item>> _items = {
    ItemType.idea: <Item>[],
    ItemType.action: <Item>[],
  };

  // relaciones bidireccionales por id
  final Map<String, Set<String>> _links = {};

  // contadores por tipo (para generar ids)
  final Map<ItemType, int> _cnt = {
    ItemType.idea: 0,
    ItemType.action: 0,
  };

  // caché por id
  final Map<String, Item> _cache = {};

  // notas (campo "tiempo") por id
  final Map<String, String> _notes = {};

  // ===== getters ============================================================
  List<Item> items(ItemType t) => List.unmodifiable(_items[t]!);
  List<Item> get all => _items.values.expand((e) => e).toList();

  Set<String> links(String id) => _links[id] ?? const <String>{};
  Item? getItem(String id) => _cache[id];

  String note(String id) => _notes[id] ?? '';

  // ===== mutaciones =========================================================
  void add(ItemType t, String text) {
    final v = text.trim();
    if (v.isEmpty) return;

    _cnt[t] = (_cnt[t] ?? 0) + 1;

    // usa la config para prefijo de id
    final cfg = t == ItemType.idea ? ideasCfg : actionsCfg;
    final id = '${cfg.prefix}${_cnt[t]!.toString().padLeft(3, '0')}';

    _items[t]!.insert(0, Item(id, v, t));
    _reindex();
    notifyListeners();
  }

  bool setStatus(String id, ItemStatus s) =>
      _update(id, (it) => it.copyWith(status: s));

  bool updateText(String id, String txt) => _update(
        id,
        (it) => Item(
          it.id,
          txt,
          it.type,
          it.status,
          it.createdAt,
          DateTime.now(),
          it.statusChanges,
        ),
      );

  void setNote(String id, String v) {
    _notes[id] = v;
    notifyListeners();
  }

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

  // ===== helpers internos ===================================================
  bool _update(String id, Item Function(Item) cb) {
    final it = _cache[id];
    if (it == null) return false;

    final L = _items[it.type]!;
    final i = L.indexWhere((e) => e.id == id);
    if (i < 0) return false;

    L[i] = cb(it);
    _reindex();
    notifyListeners();
    return true;
  }

  void _reindex() {
    _cache
      ..clear()
      ..addAll({for (final it in all) it.id: it});
  }

  // ===== importación total (reemplazo) ======================================
  /// Reemplaza TODO el estado por el pasado (items, contadores, notas, links).
  /// Asume que `links` ya viene normalizado (opcionalmente puedes pasar
  /// unidireccional y se mantendrá tal cual).
  void replaceAll({
    required List<Item> items,
    required Map<ItemType, int> counters,
    required Map<String, String> notes,
    required Map<String, Set<String>> links,
  }) {
    _items[ItemType.idea] = <Item>[];
    _items[ItemType.action] = <Item>[];

    for (final it in items) {
      _items[it.type]!.add(it);
    }

    _cnt
      ..clear()
      ..addAll({
        ItemType.idea: counters[ItemType.idea] ?? 0,
        ItemType.action: counters[ItemType.action] ?? 0,
      });

    _notes
      ..clear()
      ..addAll(notes);

    _links
      ..clear()
      ..addAll(links);

    _reindex();
    notifyListeners();
  }
}
