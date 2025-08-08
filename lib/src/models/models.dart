import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
///  MODELOS BÁSICOS
/// ---------------------------------------------------------------------------

enum ItemType { idea, action }

class Item {
  final String id;
  final String text;
  final ItemType type;

  Item({
    required this.id,
    required this.text,
    required this.type,
  });
}

class AppState {
  final List<Item> _items = [];

  List<Item> get all => List.unmodifiable(_items);

  void add(Item it) => _items.add(it);

  /// relaciones vacías (placeholder)
  List<String> links(String id) => [];
}

/// ---------------------------------------------------------------------------
///  CONFIGURACIÓN DE TIPOS (usada por QuickAdd)
/// ---------------------------------------------------------------------------

class ItemTypeCfg {
  final String prefix;
  final IconData icon;
  final String label;
  final String hint;

  const ItemTypeCfg({
    required this.prefix,
    required this.icon,
    required this.label,
    required this.hint,
  });
}

const ItemTypeCfg ideasCfg = ItemTypeCfg(
  prefix: 'B1',
  icon: Icons.lightbulb,
  label: 'Ideas',
  hint: 'Escribe tu idea…',
);

const ItemTypeCfg actionsCfg = ItemTypeCfg(
  prefix: 'B2',
  icon: Icons.assignment,
  label: 'Acciones',
  hint: 'Describe la acción…',
);
