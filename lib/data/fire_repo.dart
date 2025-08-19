// lib/data/fire_repo.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item.dart';
import '../models/enums.dart';

class FireRepo {
  FireRepo(this._db, this.uid);

  final FirebaseFirestore _db;
  final String uid;

  DocumentReference<Map<String, dynamic>> get _user =>
      _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> get _items =>
      _user.collection('items');

  CollectionReference<Map<String, dynamic>> get _links =>
      _user.collection('links'); // docs con {aId, bId}

  Stream<List<Item>> streamByType(ItemType type) {
    return _items
        .where('type', isEqualTo: type.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Item.fromDoc).toList());
  }

  Future<void> addItem(ItemType type, String text) async {
    final now = DateTime.now();
    await _items.add({
      'type': type.name,
      'text': text,
      'note': '',
      'status': 'normal',
      'createdAt': Timestamp.fromDate(now),
      'modifiedAt': Timestamp.fromDate(now),
    });
  }

  Future<void> updateText(String id, String text) async {
    await _items.doc(id).update({
      'text': text,
      'modifiedAt': Timestamp.now(),
    });
  }

  Future<void> setNote(String id, String note) async {
    await _items.doc(id).update({
      'note': note,
      'modifiedAt': Timestamp.now(),
    });
  }

  Future<void> setStatus(String id, ItemStatus s) async {
    await _items.doc(id).update({
      'status': s.name,
      'modifiedAt': Timestamp.now(),
    });
  }

  Future<void> deleteItem(String id) async {
    // Limpia enlaces del item
    final q = await _links.where('aId', isEqualTo: id).get();
    for (final d in q.docs) { await d.reference.delete(); }
    final q2 = await _links.where('bId', isEqualTo: id).get();
    for (final d in q2.docs) { await d.reference.delete(); }

    await _items.doc(id).delete();
  }

  // ---- Enlaces ----
  Stream<List<Map<String, String>>> streamLinks() async* {
    final s = _links.snapshots();
    await for (final snap in s) {
      yield snap.docs.map((d) {
        final m = d.data();
        return {'id': d.id, 'aId': '${m['aId']}', 'bId': '${m['bId']}'};
      }).toList();
    }
  }

  Future<void> link(String aId, String bId) async {
    if (aId == bId) return;
    // Evita duplicados (a,b) ~ (b,a)
    final pair1 = await _links.where('aId', isEqualTo: aId).where('bId', isEqualTo: bId).limit(1).get();
    final pair2 = await _links.where('aId', isEqualTo: bId).where('bId', isEqualTo: aId).limit(1).get();
    if (pair1.docs.isNotEmpty || pair2.docs.isNotEmpty) return;
    await _links.add({'aId': aId, 'bId': bId});
  }

  Future<void> unlink(String linkDocId) async {
    await _links.doc(linkDocId).delete();
  }
}
