// lib/data/fire_repo.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:caosbox/core/models/item.dart';
import 'package:caosbox/core/models/enums.dart';

class FireRepo {
  final FirebaseFirestore _db;
  final String _uid;

  FireRepo(this._db, this._uid);

  DocumentReference<Map<String, dynamic>> get _user =>
      _db.collection('users').doc(_uid);

  CollectionReference<Map<String, dynamic>> get _items =>
      _user.collection('items');

  CollectionReference<Map<String, dynamic>> get _links =>
      _user.collection('links');

  /* ------------ Items ------------ */

  Future<List<Item>> loadItems() async {
    final qs = await _items.get();
    return qs.docs.map(_docToItem).toList();
  }

  Item _docToItem(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    final type = (m['type'] == 'idea') ? ItemType.idea : ItemType.action;
    final status = switch (m['status']) {
      'completed' => ItemStatus.completed,
      'archived' => ItemStatus.archived,
      _ => ItemStatus.normal,
    };
    DateTime _toDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      return DateTime.tryParse('$v') ?? DateTime.now();
    }

    return Item(
      id: d.id,
      type: type,
      text: '${m['text'] ?? ''}',
      status: status,
      createdAt: _toDate(m['createdAt']),
      modifiedAt: _toDate(m['modifiedAt']),
      note: '${m['note'] ?? ''}',
      statusChanges: (m['statusChanges'] ?? 0) is int ? m['statusChanges'] : 0,
    );
  }

  Future<String> createItem(ItemType type, String text) async {
    final now = DateTime.now();
    final doc = await _items.add({
      'type': type.name,
      'text': text,
      'status': 'normal',
      'createdAt': Timestamp.fromDate(now),
      'modifiedAt': Timestamp.fromDate(now),
      'note': '',
      'statusChanges': 0,
    });
    return doc.id;
  }

  Future<void> updateText(String id, String text) async {
    await _items.doc(id).update({
      'text': text,
      'modifiedAt': Timestamp.now(),
    });
  }

  Future<void> setStatus(String id, ItemStatus st) async {
    await _items.doc(id).update({
      'status': switch (st) {
        ItemStatus.completed => 'completed',
        ItemStatus.archived => 'archived',
        _ => 'normal',
      },
      'statusChanges': FieldValue.increment(1),
      'modifiedAt': Timestamp.now(),
    });
  }

  Future<void> setNote(String id, String note) async {
    await _items.doc(id).set(
      {'note': note, 'modifiedAt': Timestamp.now()},
      SetOptions(merge: true),
    );
  }

  /* ------------ Links ------------ */
  // Guardamos pares (a,b) en orden lexicográfico para evitar duplicados.
  String _pairId(String a, String b) {
    final x = (a.compareTo(b) <= 0) ? '$a|$b' : '$b|$a';
    return x;
  }

  Future<Set<String>> loadLinksOf(String id) async {
    final qs = await _links.where('a', isEqualTo: id).get();
    final qs2 = await _links.where('b', isEqualTo: id).get();
    final out = <String>{};
    for (final d in qs.docs) {
      out.add('${d.data()['b']}');
    }
    for (final d in qs2.docs) {
      out.add('${d.data()['a']}');
    }
    out.remove(id);
    return out;
  }

  Future<void> link(String a, String b) async {
    if (a == b) return;
    final id = _pairId(a, b);
    await _links.doc(id).set({'a': a, 'b': b});
  }

  Future<void> unlink(String a, String b) async {
    final id = _pairId(a, b);
    await _links.doc(id).delete();
  }
}
