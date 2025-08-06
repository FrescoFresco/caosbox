// lib/src/models/models.dart

enum ItemType { idea, action }
enum ItemStatus { normal, completed, archived }

class Item {
  final String id, text;
  final ItemType type;
  final ItemStatus status;
  final DateTime createdAt, modifiedAt;
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

  Item copyWith({
    String? text,
    ItemStatus? status,
  }) =>
      Item(
        id,
        text ?? this.text,
        type,
        status ?? this.status,
        createdAt,
        DateTime.now(),
        this.statusChanges + ((status != null && status != this.status) ? 1 : 0),
      );
}
