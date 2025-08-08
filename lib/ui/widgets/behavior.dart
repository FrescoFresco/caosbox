import 'package:flutter/material.dart';
import '../../models/enums.dart';

class Behavior {
  static Future<bool> swipe(
    DismissDirection dir, ItemStatus st, void Function(ItemStatus) on,
  ) async {
    on(dir == DismissDirection.startToEnd
        ? (st == ItemStatus.completed ? ItemStatus.normal : ItemStatus.completed)
        : (st == ItemStatus.archived  ? ItemStatus.normal : ItemStatus.archived));
    return false;
  }

  static Widget bg(bool sec) => Container(
        color: (sec ? Colors.grey : Colors.green).withAlpha(50),
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
