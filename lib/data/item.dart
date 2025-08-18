import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final String id;
  final String text;
  final DateTime createdAt;
  final DateTime modifiedAt;

  Item({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.modifiedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'modifiedAt': Timestamp.fromDate(modifiedAt),
    };
  }

  static Item fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final created = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final modified = (data['modifiedAt'] as Timestamp?)?.toDate() ?? created;
    return Item(
      id: doc.id,
      text: (data['text'] as String?) ?? '',
      createdAt: created,
      modifiedAt: modified,
    );
  }
}
