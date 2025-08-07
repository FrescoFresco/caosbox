// lib/src/models/models.dart

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
        ItemStatus.normal    => 'Normal',
        ItemStatus.completed => 'Completado ✓',
        ItemStatus.archived  => 'Archivado 📁'
      };
}

/// ===== APP STATE =====

class AppState extends ChangeNotifier {
  final Map<ItemType, List<Item>> _items = {
    ItemType.idea:   [],
    ItemType.action: []
  };
  final Map<String, Set<String>> _links = {};
  final Map<ItemType, int> _cnt = {
    ItemType.idea:   0,
    ItemType.action: 0
  };
  final Map<String, Item> _cache = {};
  final Map<String, String> _notes = {};

  String note(String id) => _notes[id] ?? '';
  void setNote(String id, String v) { _notes[id] = v; notifyListeners(); }

  List<Item> items(ItemType t)           => List.unmodifiable(_items[t]!);
  List<Item> get all                    => _items.values.expand((e) => e).toList();
  Set<String> links(String id)          => _links[id] ?? {};
  Item? getItem(String id)              => _cache[id];

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
    final L = _items[it.type]!, i = L.indexWhere((e) => e.id == id);
    if (i < 0) return false;
    L[i] = ch(it);
    _reindex();
    notifyListeners();
    return true;
  }

  bool setStatus(String id, ItemStatus s) => _up(id, (it) => it.copyWith(status: s));
  bool updateText(String id, String t)    => _up(id, (it) => Item(it.id, t, it.type, it.status, it.createdAt, DateTime.now(), it.statusChanges));

  void toggleLink(String a, String b) {
    if (a == b || _cache[a] == null || _cache[b] == null) return;
    final sa = _links.putIfAbsent(a, () => <String>{});
    final sb = _links.putIfAbsent(b, () => <String>{});
    if (sa.remove(b)) sb.remove(a); else { sa.add(b); sb.add(a); }
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
  static const title   = TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
  static const id      = TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500);
  static const content = TextStyle(fontSize: 14);
  static const info    = TextStyle(fontWeight: FontWeight.w600);

  static BoxDecoration get card => BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      );

  static const statusIcons = {
    ItemStatus.completed: {'icon': Icons.check,    'color': Colors.green},
    ItemStatus.archived:  {'icon': Icons.archive,  'color': Colors.grey},
  };
}

class Behavior {
  static Future<bool> swipe(
      DismissDirection d, ItemStatus s, void Function(ItemStatus) on) async {
    on(d == DismissDirection.startToEnd
      ? (s == ItemStatus.completed ? ItemStatus.normal : ItemStatus.completed)
      : (s == ItemStatus.archived  ? ItemStatus.normal : ItemStatus.archived)
    );
    return false;
  }

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
