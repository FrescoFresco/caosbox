import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum ItemType { idea, action }
enum ItemStatus { normal, completed, archived }

extension ItemTypeX on ItemType {
  String get name => this == ItemType.idea ? 'idea' : 'action';
  IconData get icon => this == ItemType.idea ? Icons.lightbulb : Icons.assignment;
  String get label => this == ItemType.idea ? 'Ideas' : 'Acciones';
}

extension ItemStatusX on ItemStatus {
  String get name => switch (this) {
        ItemStatus.normal => 'normal',
        ItemStatus.completed => 'completed',
        ItemStatus.archived => 'archived',
      };
}

ItemType itemTypeFrom(String s) => s == 'action' ? ItemType.action : ItemType.idea;
ItemStatus itemStatusFrom(String s) => switch (s) {
      'completed' => ItemStatus.completed,
      'archived' => ItemStatus.archived,
      _ => ItemStatus.normal,
    };

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
  }) =>
      Item(
        id: id,
        type: type,
        text: text ?? this.text,
        note: note ?? this.note,
        status: status ?? this.status,
        createdAt: createdAt,
        modifiedAt: modifiedAt ?? this.modifiedAt,
      );

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'text': text,
        'note': note,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'modifiedAt': Timestamp.fromDate(modifiedAt),
      };

  static Item fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    DateTime _ts(dynamic v) =>
        v is Timestamp ? v.toDate() : (DateTime.tryParse('$v') ?? DateTime.now());
    return Item(
      id: doc.id,
      type: itemTypeFrom('${d['type'] ?? 'idea'}'),
      text: '${d['text'] ?? ''}',
      note: '${d['note'] ?? ''}',
      status: itemStatusFrom('${d['status'] ?? 'normal'}'),
      createdAt: _ts(d['createdAt']),
      modifiedAt: _ts(d['modifiedAt']),
    );
  }
}
