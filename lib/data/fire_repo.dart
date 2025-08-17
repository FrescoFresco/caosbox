import 'package:cloud_firestore/cloud_firestore.dart';

class CaosItem {
  final String id;
  final String text;
  final bool done;
  final DateTime? createdAt;
  final DateTime? modifiedAt;

  CaosItem({
    required this.id,
    required this.text,
    required this.done,
    this.createdAt,
    this.modifiedAt,
  });

  factory CaosItem.fromMap(String id, Map<String, dynamic> m) {
    DateTime? _toDt(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return null;
    }

    return CaosItem(
      id: id,
      text: (m['text'] ?? '') as String,
      done: (m['done'] ?? false) as bool,
      createdAt: _toDt(m['createdAt']),
      modifiedAt: _toDt(m['modifiedAt']),
    );
  }
}

class FireRepo {
  final FirebaseFirestore _db;
  final String uid;

  FireRepo(this._db, this.uid);

  DocumentReference<Map<String, dynamic>> get _user =>
      _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> get _items =>
      _user.collection('items');

  Stream<List<CaosItem>> watchItems() {
    return _items.orderBy('createdAt', descending: true).snapshots().map(
          (qs) => qs.docs
              .map((d) => CaosItem.fromMap(d.id, d.data()))
              .toList(growable: false),
        );
  }

  Future<void> addItem(String text) async {
    await _items.add({
      'text': text,
      'done': false,
      'createdAt': FieldValue.serverTimestamp(),
      'modifiedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleDone(String id, bool done) async {
    await _items.doc(id).set({
      'done': done,
      'modifiedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteItem(String id) => _items.doc(id).delete();
}
