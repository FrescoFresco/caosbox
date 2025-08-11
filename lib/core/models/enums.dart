import 'package:flutter/material.dart';

enum ItemType { idea, action }
enum ItemStatus { normal, completed, archived }

extension ItemStatusName on ItemStatus {
  String get name => switch (this) {
        ItemStatus.normal => 'Normal',
        ItemStatus.completed => 'Completado ✓',
        ItemStatus.archived => 'Archivado 📁',
      };
}

IconData typeIcon(ItemType t) => t == ItemType.idea ? Icons.lightbulb : Icons.assignment;
String typeLabel(ItemType t)   => t == ItemType.idea ? 'Ideas' : 'Acciones';
