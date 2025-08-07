// lib/src/utils/behavior.dart
import 'package:flutter/material.dart';
import '../models/item.dart';

class Behavior {
  static Future<bool> swipe(
      DismissDirection d, ItemStatus s, void Function(ItemStatus) on) async {
    final next = d == DismissDirection.startToEnd
        ? (s == ItemStatus.completed ? ItemStatus.normal : ItemStatus.completed)
        : (s == ItemStatus.archived ? ItemStatus.normal : ItemStatus.archived);
    on(next);
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
