// lib/data/fire_repo.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'item.dart';

class FireRepo {
  final FirebaseFirestore _db;
  final String uid;

  FireRepo(this._db, this.uid);

  CollectionReference<Map<String, dynamic>> get _itemsCol =>
      _db.collection('users').doc(uid).collection('items');

  /// Stream en tiempo real (ordenado por creación desc)
  Stream<List<Item>> streamItems() {
    return _itemsCol
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Item.fromDoc).toList());
  }

  /// Crea un item
  Future<void> addItem(String text) async {
    final now = DateTime.now();
    await _itemsCol.add({
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'modifiedAt': FieldValue.serverTimestamp(),
      // si algún día quieres guardar más campos, añádelos aquí
    });
  }

  /// Actualiza el texto del item
  Future<void> updateItem(String id, String text) async {
    await _itemsCol.doc(id).update({
      'text': text,
      'modifiedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Borra un item
  Future<void> deleteItem(String id) async {
    await _itemsCol.doc(id).delete();
  }
}
