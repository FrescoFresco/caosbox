import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item.dart';

class FireRepo {
  final FirebaseFirestore _db;
  final String uid;
  FireRepo(this._db, this.uid);

  DocumentReference<Map<String, dynamic>> get _user =>
      _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> get _items =>
      _user.collection('items');

  CollectionReference<Map<String, dynamic>> get _links =>
      _user.collection('links');

  /// Lista completa (orden invertido por fecha)
  Stream<List<Item>> watchAll() => _items
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Item.fromDoc).toList());

  Stream<List<Item>> watchByType(ItemType t) =>
      watchAll().map((list) => list.where((e) => e.type == t).toList());

  /// Mapa de adyacencias: id -> set de ids conectados
  Stream<Map<String, Set<String>>> watchLinks() => _links.snapshots().map((s) {
        final m = <String, Set<String>>{};
        for (final d in s.docs) {
          final a = '${d.data()['a']}';
          final b = '${d.data()['b']}';
          m.putIfAbsent(a, () => <String>{}).add(b);
          m.putIfAbsent(b, () => <String>{}).add(a);
        }
        return m;
      });

  Future<String> addItem(ItemType t, String text) async {
    final now = DateTime.now();
    final ref = await _items.add({
      'type': t.name,
      'text': text,
      'note': '',
      'status': 'normal',
      'createdAt': Timestamp.fromDate(now),
      'modifiedAt': Timestamp.fromDate(now),
    });
    return ref.id;
  }

  Future<void> updateText(String id, String text) =>
      _items.doc(id).update({'text': text, 'modifiedAt': Timestamp.now()});

  Future<void> updateNote(String id, String note) =>
      _items.doc(id).update({'note': note, 'modifiedAt': Timestamp.now()});

  Future<void> setStatus(String id, ItemStatus st) =>
      _items.doc(id).update({'status': st.name, 'modifiedAt': Timestamp.now()});

  Future<void> deleteItem(String id) => _items.doc(id).delete();

  String _key(String a, String b) {
    final x = a.compareTo(b) <= 0 ? '$a|$b' : '$b|$a';
    return x;
  }

  Future<void> toggleLink(String a, String b) async {
    if (a == b) return;
    final key = _key(a, b);
    final ref = _links.doc(key);
    final snap = await ref.get();
    if (snap.exists) {
      await ref.delete();
    } else {
      await ref.set({
        'a': a.compareTo(b) <= 0 ? a : b,
        'b': a.compareTo(b) <= 0 ? b : a,
        'createdAt': Timestamp.now(),
      });
    }
  }

  Future<bool> hasLink(String a, String b) async {
    final key = _key(a, b);
    final snap = await _links.doc(key).get();
    return snap.exists;
  }
}
