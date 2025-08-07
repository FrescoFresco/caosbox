import 'package:flutter/material.dart';
import '../models/models.dart';

class Behavior {
  static Future<bool> swipe(
      DismissDirection dir, ItemStatus now, Function(ItemStatus) on) async {
    on(dir == DismissDirection.startToEnd
        ? (now == ItemStatus.completed ? ItemStatus.normal : ItemStatus.completed)
        : (now == ItemStatus.archived ? ItemStatus.normal : ItemStatus.archived));
    return false; // no dismiss
  }

  static Widget bg(bool secondary) => Container(
        color: (secondary ? Colors.grey : Colors.green).withOpacity(.2),
        alignment: secondary ? Alignment.centerRight : Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Icon(secondary ? Icons.archive : Icons.check),
      );
}
