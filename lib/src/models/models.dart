import 'package:flutter/material.dart';

/// ────────────────────────────────────────────────────────────────────────────
/// ENUMS
/// ────────────────────────────────────────────────────────────────────────────
enum ItemType   { idea, action }
enum ItemStatus { normal, completed, archived }

/// ────────────────────────────────────────────────────────────────────────────
/// DATA MODEL
/// ────────────────────────────────────────────────────────────────────────────
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

/// ────────────────────────────────────────────────────────────────────────────
/// APP-STATE (Dummy in-memory store solo para compilar)
/// ────────────────────────────────────────────────────────────────────────────
class AppState {
  final List<Item> _items = [];

  /// Devuelve TODA la lista inmutable
  List<Item> get all => List.unmodifiable(_items);

  /// Devuelve solo items del tipo indicado
  List<Item> items(ItemType t) =>
      _items.where((e) => e.type == t).toList(growable: false);

  /// Relaciones vacías (placeholder)
  List<String> links(String id) => [];

  void add(Item it) => _items.add(it);
}

/// ────────────────────────────────────────────────────────────────────────────
/// CONFIG-UI para QuickAdd
/// ────────────────────────────────────────────────────────────────────────────
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

const ItemTypeCfg ideasCfg   = ItemTypeCfg(
  prefix: 'B1',
  icon  : Icons.lightbulb,
  label : 'Ideas',
  hint  : 'Escribe tu idea…',
);

const ItemTypeCfg actionsCfg = ItemTypeCfg(
  prefix: 'B2',
  icon  : Icons.assignment,
  label : 'Acciones',
  hint  : 'Describe la acción…',
);
