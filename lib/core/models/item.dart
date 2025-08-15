import 'package:caosbox/core/models/enums.dart';

class Item {
  final String id;
  final String text;
  final ItemType type;
  final ItemStatus status;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final int statusChanges;

  Item(
    this.id,
    this.text,
    this.type, {
    this.status = ItemStatus.normal,
    DateTime? createdAt,
    DateTime? modifiedAt,
    this.statusChanges = 0,
  })  : createdAt = createdAt ?? DateTime.now(),
        modifiedAt = modifiedAt ?? DateTime.now();

  Item copyWith({
    ItemStatus? status,
    String? text,
    DateTime? modifiedAt,
    int? statusChanges,
  }) {
    return Item(
      id,
      text ?? this.text,
      type,
      status: status ?? this.status,
      createdAt: createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      statusChanges: statusChanges ?? this.statusChanges,
    );
  }
}
