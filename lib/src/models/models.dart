import 'package:flutter/material.dart';

/* ─── ENUMS ─────────────────────────────────────────────── */
enum ItemType   { idea, action }
enum ItemStatus { normal, completed, archived }

/* ─── DATA CLASS ────────────────────────────────────────── */
class Item {
  final String id, text;
  final ItemType type;
  final ItemStatus status;
  Item(this.id, this.text, this.type, [this.status = ItemStatus.normal]);

  Item copyWith({ItemStatus? status}) =>
      Item(id, text, type, status ?? this.status);
}

/* ─── APP STATE (in-memory) ─────────────────────────────── */
class AppState extends ChangeNotifier {
  final _map = <ItemType, List<Item>>{
    ItemType.idea   : [],
    ItemType.action : []
  };

  List<Item> items(ItemType t) => List.unmodifiable(_map[t]!);

  void add(ItemType t, String text) {
    _map[t]!.add(Item('${t.name}_${_map[t]!.length+1}', text, t));
    notifyListeners();
  }

  // Placeholder links
  final _links = <String, Set<String>>{};
  Set<String> links(String id) => _links[id] ?? {};
}

/* ─── FILTER SUPPORT (simple) ───────────────────────────── */
enum FilterMode { off, include, exclude }
enum FilterKey  { completed, archived, hasLinks }

class FilterSet {
  final text = TextEditingController();
  final modes = {
    FilterKey.completed : FilterMode.off,
    FilterKey.archived  : FilterMode.off,
    FilterKey.hasLinks  : FilterMode.off,
  };
  void dispose() => text.dispose();
}

/* ─── VISUAL HELPERS ───────────────────────────────────── */
class Style {
  static const card   = BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(8)));
  static const id     = TextStyle(fontSize: 12, color: Colors.grey);
  static const content= TextStyle(fontSize: 14);
}

class Behavior {
  static Future<bool> swipe(_, __, ___) async => false;
}

/* ─── ITEM TYPE CONFIGS ────────────────────────────────── */
class ItemTypeCfg {
  final String prefix, hint;
  final IconData icon;
  const ItemTypeCfg(this.prefix, this.hint, this.icon);
}

const ideasCfg   = ItemTypeCfg('B1', 'Escribe tu idea…', Icons.lightbulb);
const actionsCfg = ItemTypeCfg('B2', 'Describe la acción…', Icons.assignment);
