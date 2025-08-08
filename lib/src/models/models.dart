import 'package:flutter/material.dart';

/// ──────────────────────────────────────────────────────────
/// ENUMS
/// ──────────────────────────────────────────────────────────
enum ItemType   { idea, action }
enum ItemStatus { normal, completed, archived }

/// ──────────────────────────────────────────────────────────
/// CORE ITEM
/// ──────────────────────────────────────────────────────────
class Item {
  final String      id;
  final String      text;
  final ItemType    type;
  final ItemStatus  status;

  Item({
    required this.id,
    required this.text,
    required this.type,
    this.status = ItemStatus.normal,
  });
}

/// ──────────────────────────────────────────────────────────
/// IN-MEMORY APP STATE  (placeholder simple; ajústalo a tu lógica)
/// ──────────────────────────────────────────────────────────
class AppState extends ChangeNotifier {
  final List<Item> _items = [];

  List<Item> get all => List.unmodifiable(_items);

  List<Item> items(ItemType t) =>
      _items.where((e) => e.type == t).toList(growable: false);

  List<String> links(String id) => [];           // placeholder

  void add(Item it) {
    _items.add(it);
    notifyListeners();
  }
}

/// ──────────────────────────────────────────────────────────
/// CONFIGURACIÓN UI  (QuickAdd)
/// ──────────────────────────────────────────────────────────
class ItemTypeCfg {
  final String    prefix;
  final IconData  icon;
  final String    label;
  final String    hint;
  const ItemTypeCfg({
    required this.prefix,
    required this.icon,
    required this.label,
    required this.hint,
  });
}

const ideasCfg   = ItemTypeCfg(
  prefix: 'B1',
  icon  : Icons.lightbulb,
  label : 'Ideas',
  hint  : 'Escribe tu idea…',
);

const actionsCfg = ItemTypeCfg(
  prefix: 'B2',
  icon  : Icons.assignment,
  label : 'Acciones',
  hint  : 'Describe la acción…',
);
