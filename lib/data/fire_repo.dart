import 'package:cloud_firestore/cloud_firestore.dart';
import 'item.dart';

class FireRepo {
  final FirebaseFirestore _db;
  final String uid;

  FireRepo(this._db, this.uid);

  CollectionReference<Map<String, dynamic>> get _itemsCol =>
      _db.collection('users').doc(uid).collection('items');

  Stream<List<Item>> streamItems() {
    return _itemsCol
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Item.fromDoc).toList());
  }

  Future<void> addItem(String text) async {
    await _itemsCol.add({
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'modifiedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateItem(String id, String text) async {
    await _itemsCol.doc(id).update({
      'text': text,
      'modifiedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteItem(String id) async {
    await _itemsCol.doc(id).delete();
  }
}
