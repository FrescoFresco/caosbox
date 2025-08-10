import 'enums.dart';

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
    this.type, [
    this.status = ItemStatus.normal,
    DateTime? c,
    DateTime? m,
    this.statusChanges = 0,
  ])  : createdAt = c ?? DateTime.now(),
        modifiedAt = m ?? DateTime.now();

  Item copyWith({String? text, ItemStatus? status, DateTime? modifiedAt, int? statusChanges}) {
    return Item(
      id,
      text ?? this.text,
      type,
      status ?? this.status,
      createdAt,
      modifiedAt ?? this.modifiedAt,
      statusChanges ?? this.statusChanges,
    );
  }
}
