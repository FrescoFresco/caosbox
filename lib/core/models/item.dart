import 'enums.dart';

class Item {
  final String id, text;
  final ItemType type;
  final ItemStatus status;
  final DateTime createdAt, modifiedAt;
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
    String? text,
    ItemStatus? status,
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

extension DateFmt on DateTime {
  String _two(int n) => n.toString().padLeft(2, '0');
  String get f => '${_two(day)}/${_two(month)}/$year ${_two(hour)}:${_two(minute)}';
}
