import 'package:caosbox/core/models/enums.dart';

class Item {
  final String id;
  final String text;
  final ItemType type;
  final ItemStatus status;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final int statusChanges;

  Item({
    required this.id,
    required this.text,
    required this.type,
    this.status = ItemStatus.normal,
    DateTime? createdAt,
    DateTime? modifiedAt,
    this.statusChanges = 0,
  })  : createdAt = createdAt ?? DateTime.now(),
        modifiedAt = modifiedAt ?? DateTime.now();

  Item copyWith({
    String? text,
    ItemStatus? status,
    DateTime? createdAt,
    DateTime? modifiedAt,
    int? statusChanges,
  }) {
    return Item(
      id: id,
      text: text ?? this.text,
      type: type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      statusChanges: statusChanges ?? this.statusChanges,
    );
  }

  Item copyWithStatus(ItemStatus s) {
    final changed = s != status;
    return Item(
      id: id,
      text: text,
      type: type,
      status: s,
      createdAt: createdAt,
      modifiedAt: changed ? DateTime.now() : modifiedAt,
      statusChanges: changed ? statusChanges + 1 : statusChanges,
    );
  }
}
