// lib/src/models/item.dart
enum ItemType { idea, action }
enum ItemStatus { normal, completed, archived }

class Item {
  final String id, text;
  final ItemType type;
  final ItemStatus status;
  final DateTime createdAt, modifiedAt;
  final int statusChanges;

  Item(this.id, this.text, this.type,
      [this.status = ItemStatus.normal,
      DateTime? c,
      DateTime? m,
      this.statusChanges = 0])
      : createdAt = c ?? DateTime.now(),
        modifiedAt = m ?? DateTime.now();

  Item copyWith({ItemStatus? status}) {
    final ns = status ?? this.status;
    final chg = ns != this.status;
    return Item(id, text, type, ns, createdAt,
        chg ? DateTime.now() : modifiedAt, chg ? statusChanges + 1 : statusChanges);
  }
}

extension DateFmt on DateTime {
  String two(int n) => n.toString().padLeft(2, '0');
  String get f =>
      '${two(day)}/${two(month)}/${year} ${two(hour)}:${two(minute)}';
}

extension StatusName on ItemStatus {
  String get name => switch (this) {
        ItemStatus.normal => 'Normal',
        ItemStatus.completed => 'Completado ✓',
        ItemStatus.archived => 'Archivado 📁'
      };
}

// Configuration for prefixes & icons
import 'package:flutter/material.dart';
class ItemTypeCfg {
  final String prefix, hint, label;
  final IconData icon;
  const ItemTypeCfg({
    required this.prefix,
    required this.icon,
    required this.label,
    required this.hint,
  });
}
const ideasCfg = ItemTypeCfg(
    prefix: 'B1', icon: Icons.lightbulb, label: 'Ideas', hint: 'Escribe tu idea...');
const actionsCfg = ItemTypeCfg(
    prefix: 'B2', icon: Icons.assignment, label: 'Acciones', hint: 'Describe la acción...');
