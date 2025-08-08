// lib/src/models/models.dart
import 'package:flutter/material.dart';

/* ─── TIPOS BÁSICOS ───────────────────────────────────────────────────────── */

enum ItemType   { idea, action }
enum ItemStatus { normal, completed, archived }

class Item {
  final String     id;
  final String     text;
  final ItemType   type;
  final ItemStatus status;
  final DateTime   createdAt;
  final DateTime   modifiedAt;
  final int        statusChanges;

  Item(
    this.id,
    this.text,
    this.type, {
    this.status = ItemStatus.normal,
    DateTime? created,
    DateTime? modified,
    this.statusChanges = 0,
  })  : createdAt  = created  ?? DateTime.now(),
        modifiedAt = modified ?? DateTime.now();

  Item copyWith({ItemStatus? status}) {
    final ns  = status ?? this.status;
    final chg = ns != this.status;
    return Item(
      id,
      text,
      type,
      status:        ns,
      created:       createdAt,
      modified:      chg ? DateTime.now() : modifiedAt,
      statusChanges: chg ? statusChanges + 1 : statusChanges,
    );
  }
}

/* ─── ESTILO / COMPORTAMIENTO PARA WIDGETS ──────────────────────────────── */

class Style {
  static const title   = TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
  static const id      = TextStyle(fontSize: 12, color: Colors.grey);
  static const content = TextStyle(fontSize: 14);

  static BoxDecoration get card => BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      );

  static const statusIcons = <ItemStatus, Map<String, dynamic>>{
    ItemStatus.completed : { 'icon': Icons.check   , 'color': Colors.green },
    ItemStatus.archived  : { 'icon': Icons.archive , 'color': Colors.grey  },
  };
}

class Behavior {
  static Future<bool> swipe(
    DismissDirection dir,
    ItemStatus        cur,
    void Function(ItemStatus) act,
  ) async {
    final next = dir == DismissDirection.startToEnd
        ? (cur == ItemStatus.completed ? ItemStatus.normal : ItemStatus.completed)
        : (cur == ItemStatus.archived  ? ItemStatus.normal : ItemStatus.archived);
    act(next);
    return false;
  }

  static Widget bg(bool secondary) => Container(
        color: (secondary ? Colors.grey : Colors.green).withOpacity(0.20),
        child: Align(
          alignment: secondary ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Icon(
              secondary ? Icons.archive : Icons.check,
              color: secondary ? Colors.grey : Colors.green,
            ),
          ),
        ),
      );
}

/* ─── ESTADO GLOBAL ─────────────────────────────────────────────────────── */

class AppState extends ChangeNotifier {
  final _byType  = <ItemType, List<Item>>{
    ItemType.idea   : <Item>[],
    ItemType.action : <Item>[],
  };
  final _links = <String, Set<String>>{};
  final _idCnt = <ItemType, int>{};

  // --- CRUD ----------------------------------------------------------------
  void add(ItemType t, String raw) {
    final text = raw.trim();
    if (text.isEmpty) return;

    final n   = (_idCnt[t] ?? 0) + 1;
    _idCnt[t] = n;
    final id  = (t == ItemType.idea ? 'B1' : 'B2') + n.toString().padLeft(3, '0');

    _byType[t]!.insert(0, Item(id, text, t));
    notifyListeners();
  }

  bool setStatus(String id, ItemStatus s) => _update(id, (it) => it.copyWith(status: s));
  bool updateText(String id, String txt)  => _update(id,
        (it) => Item(it.id, txt, it.type,
          status       : it.status,
          created      : it.createdAt,
          modified     : DateTime.now(),
          statusChanges: it.statusChanges,
        ));

  // --- utilidades ----------------------------------------------------------
  List<Item> items(ItemType t) => List.unmodifiable(_byType[t]!);
  List<Item> get all           => _byType.values.expand((e) => e).toList();

  Set<String> links(String id) => _links[id] ?? const {};

  void toggleLink(String a, String b) {
    if (a == b) return;
    final sa = _links.putIfAbsent(a, () => <String>{});
    final sb = _links.putIfAbsent(b, () => <String>{});
    if (sa.remove(b)) {
      sb.remove(a);
    } else {
      sa.add(b); sb.add(a);
    }
    notifyListeners();
  }

  // --- helper privado ------------------------------------------------------
  bool _update(String id, Item Function(Item) builder) {
    final it = all.firstWhere((e) => e.id == id, orElse: () => Item('','',ItemType.idea));
    if (it.id.isEmpty) return false;
    final L   = _byType[it.type]!;
    final idx = L.indexWhere((e) => e.id == id);
    L[idx]    = builder(it);
    notifyListeners();
    return true;
  }
}
