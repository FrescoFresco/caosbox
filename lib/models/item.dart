import 'enums.dart';

class Item {
  final String id, text;
  final ItemType type;
  final ItemStatus status;
  final DateTime createdAt, modifiedAt;
  final int statusChanges;

  Item(this.id, this.text, this.type,
      [this.status = ItemStatus.normal,
       DateTime? c, DateTime? m, this.statusChanges = 0])
      : createdAt  = c ?? DateTime.now(),
        modifiedAt = m ?? DateTime.now();

  Item copyWith({ItemStatus? status}) {
    final ns   = status ?? this.status;
    final diff = ns != this.status;
    return Item(id, text, type, ns, createdAt,
        diff ? DateTime.now() : modifiedAt, diff ? statusChanges + 1 : statusChanges);
  }
}
