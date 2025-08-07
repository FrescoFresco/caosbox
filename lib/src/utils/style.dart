import 'package:flutter/material.dart';
import '../models/item.dart';

class Style {
  static const title = TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
  static const id =
      TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500);
  static const content = TextStyle(fontSize: 14);
  static const info = TextStyle(fontWeight: FontWeight.w600);

  static BoxDecoration get card => BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      );

  static const statusIcons = {
    ItemStatus.completed: {'icon': Icons.check, 'color': Colors.green},
    ItemStatus.archived: {'icon': Icons.archive, 'color': Colors.grey},
  };
}
