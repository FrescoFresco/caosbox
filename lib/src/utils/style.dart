import 'package:flutter/material.dart';
import '../models/models.dart';

class Style {
  static const card = BoxDecoration(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      border: Border.fromBorderSide(BorderSide(color: Colors.black12)));
  static const statusIcons = {
    ItemStatus.completed: Icons.check,
    ItemStatus.archived: Icons.archive
  };
}
