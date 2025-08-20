import 'package:cloud_firestore/cloud_firestore.dart';

enum ItemType { b1, b2 }
enum ItemStatus { normal, completed, archived }

ItemType itemTypeFromString(String s) => s == 'b2' ? ItemType.b2 : ItemType.b1;
String itemTypeToString(ItemType t) => t == ItemType.b2 ? 'b2' : 'b1';

ItemStatus itemStatusFromString(String s) {
  switch (s) {
    case 'completed':
      return ItemStatus.completed;
    case 'archived':
      return ItemStatus.archived;
    default:
      return ItemStatus.normal;
  }
}

String itemStatusToString(ItemStatus s) {
  switch (s) {
    case ItemStatus.completed:
      return 'completed';
    case ItemStatus.archived:
      return 'archived';
    case ItemStatus.normal:
    default:
      return 'normal';
  }
}

class Item {
  final String id;
  final ItemType type;
  final String text;
  final String note;
  final List<String> tags;
  final ItemStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? startAt;
  final DateTime? dueAt;

  const Item({
    required this.id,
    required this.type,
    required this.text,
    this.note = '',
    this.tags = const [],
    this.status = ItemStatus.normal,
    required this.createdAt,
    required this.updatedAt,
    this.startAt,
    this.dueAt,
  });

  Item copyWith({
    String? id,
    ItemType? type,
    String? text,
    String? note,
    List<String>? tags,
    ItemStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startAt,
    DateTime? dueAt,
  }) =>
      Item(
        id: id ?? this.id,
        type: type ?? this.type,
        text: text ?? this.text,
        note: note ?? this.note,
        tags: tags ?? this.tags,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        startAt: startAt ?? this.startAt,
        dueAt: dueAt ?? this.dueAt,
      );

  Map<String, dynamic> toMap() => {
        'type': itemTypeToString(type),
        'text': text,
        'note': note,
        'tags': tags,
        'status': itemStatusToString(status),
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'startAt': startAt == null ? null : Timestamp.fromDate(startAt!),
        'dueAt': dueAt == null ? null : Timestamp.fromDate(dueAt!),
      };

  static Item fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    DateTime? _ts(dynamic v) => v is Timestamp ? v.toDate() : null;
    return Item(
      id: d.id,
      type: itemTypeFromString(m['type'] ?? 'b1'),
      text: (m['text'] ?? '').toString(),
      note: (m['note'] ?? '').toString(),
      tags: (m['tags'] is List) ? (m['tags'] as List).cast<String>() : <String>[],
      status: itemStatusFromString((m['status'] ?? 'normal').toString()),
      createdAt: _ts(m['createdAt']) ?? DateTime.now(),
      updatedAt: _ts(m['updatedAt']) ?? DateTime.now(),
      startAt: _ts(m['startAt']),
      dueAt: _ts(m['dueAt']),
    );
  }
}
