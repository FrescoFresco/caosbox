// lib/core/models/item.dart
import 'package:caosbox/core/models/enums.dart';

class Item {
  final String id;
  final ItemType type;
  final String text;
  final ItemStatus status;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final String note;
  final int statusChanges;

  Item({
    required this.id,
    required this.type,
    required this.text,
    this.status = ItemStatus.normal,
    required this.createdAt,
    required this.modifiedAt,
    this.note = '',
    this.statusChanges = 0,
  });

  Item copyWith({
    String? id,
    ItemType? type,
    String? text,
    ItemStatus? status,
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? note,
    int? statusChanges,
  }) {
    return Item(
      id: id ?? this.id,
      type: type ?? this.type,
      text: text ?? this.text,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      note: note ?? this.note,
      statusChanges: statusChanges ?? this.statusChanges,
    );
  }
}
