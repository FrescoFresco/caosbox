// lib/models/item.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

class Item {
  final String id;
  final ItemType type;
  final String text;
  final String note;
  final ItemStatus status;
  final DateTime createdAt;
  final DateTime modifiedAt;

  Item({
    required this.id,
    required this.type,
    required this.text,
    this.note = '',
    this.status = ItemStatus.normal,
    required this.createdAt,
    required this.modifiedAt,
  });

  Item copyWith({
    String? text,
    String? note,
    ItemStatus? status,
    DateTime? modifiedAt,
  }) {
    return Item(
      id: id,
      type: type,
      text: text ?? this.text,
      note: note ?? this.note,
      status: status ?? this.status,
      createdAt: createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'text': text,
      'note': note,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'modifiedAt': Timestamp.fromDate(modifiedAt),
    };
  }

  static Item fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final type = (d['type'] == 'action') ? ItemType.action : ItemType.idea;
    final statusStr = (d['status'] ?? 'normal') as String;
    final status = switch (statusStr) {
      'completed' => ItemStatus.completed,
      'archived' => ItemStatus.archived,
      _ => ItemStatus.normal,
    };
    DateTime parseTS(dynamic v) =>
        v is Timestamp ? v.toDate() : (DateTime.tryParse('$v') ?? DateTime.now());

    return Item(
      id: doc.id,
      type: type,
      text: (d['text'] ?? '') as String,
      note: (d['note'] ?? '') as String,
      status: status,
      createdAt: parseTS(d['createdAt']),
      modifiedAt: parseTS(d['modifiedAt']),
    );
  }
}
