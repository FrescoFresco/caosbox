// lib/models.dart
enum ItemType { idea, action }

extension ItemTypeX on ItemType {
  String get asString => this == ItemType.idea ? 'idea' : 'action';
  String get prefix   => this == ItemType.idea ? 'B'     : 'A';
}

class Item {
  final String idHuman;     // B1002 / A0042 (docId)
  final ItemType type;
  final String text;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Item({
    required this.idHuman,
    required this.type,
    required this.text,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  Item copyWith({
    String? text,
    String? note,
    DateTime? updatedAt,
  }) => Item(
    idHuman: idHuman,
    type: type,
    text: text ?? this.text,
    note: note ?? this.note,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  static Item fromMap(Map<String, dynamic> m) {
    final t = (m['type'] as String?) == 'action' ? ItemType.action : ItemType.idea;
    DateTime parseTs(dynamic v) {
      if (v == null) return DateTime.now();
      // Firestore Timestamp to DateTime or ISO string
      if (v is DateTime) return v;
      if (v is String)  return DateTime.tryParse(v) ?? DateTime.now();
      final s = '$v';
      return DateTime.tryParse(s) ?? DateTime.now();
    }
    return Item(
      idHuman: m['idHuman'] ?? '',
      type: t,
      text: m['text'] ?? '',
      note: m['note'] ?? '',
      createdAt: parseTs(m['createdAt']),
      updatedAt: parseTs(m['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'idHuman': idHuman,
    'type': type.asString,
    'text': text,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}
