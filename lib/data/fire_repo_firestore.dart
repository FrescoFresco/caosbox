import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/item.dart';
import 'repo.dart';

class FireRepoFirestore implements Repo {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _items => _db.collection('users').doc(_uid).collection('items');
  CollectionReference<Map<String, dynamic>> get _links => _db.collection('users').doc(_uid).collection('links');
  CollectionReference<Map<String, dynamic>> get _linksOf => _db.collection('users').doc(_uid).collection('linksOf');

  @override
  Stream<List<Item>> streamByType(ItemType t) => _items
      .where('type', isEqualTo: itemTypeToString(t))
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Item.fromDoc).toList());

  @override
  Stream<Item?> streamItem(String id) => _items.doc(id).snapshots().map((d) => d.exists ? Item.fromDoc(d) : null);

  @override
  Future<String> addItem(ItemType t, {required String text, String note = '', List<String> tags = const []}) async {
    final now = DateTime.now();
    final ref = await _items.add({
      'type': itemTypeToString(t),
      'text': text,
      'note': note,
      'tags': tags,
      'status': 'normal',
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'startAt': null,
      'dueAt': null,
    });
    return ref.id;
  }

  @override
  Future<void> updateItem(Item it) async =>
      _items.doc(it.id).update(it.copyWith(updatedAt: DateTime.now()).toMap());

  @override
  Future<void> setStatus(String id, ItemStatus s) async => _items.doc(id).update({
        'status': itemStatusToString(s),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

  @override
  Future<void> deleteItem(String id) async {
    final peers = await _linksOf.doc(id).collection('peers').get();
    for (final d in peers.docs) { await unlink(id, d.id); }
    await _items.doc(id).delete();
  }

  @override
  Stream<Set<String>> streamLinksOf(String id) =>
      _linksOf.doc(id).collection('peers').snapshots().map((s) => s.docs.map((d) => d.id).toSet());

  @override
  Future<void> link(String a, String b) async {
    if (a == b) return;
    final k = canonicalKey(a, b);
    final now = Timestamp.fromDate(DateTime.now());
    final batch = _db.batch();
    batch.set(_links.doc(k), {'a': a, 'b': b, 'createdAt': now});
    batch.set(_linksOf.doc(a).collection('peers').doc(b), {'createdAt': now});
    batch.set(_linksOf.doc(b).collection('peers').doc(a), {'createdAt': now});
    await batch.commit();
  }

  @override
  Future<void> unlink(String a, String b) async {
    final k = canonicalKey(a, b);
    final batch = _db.batch();
    batch.delete(_links.doc(k));
    batch.delete(_linksOf.doc(a).collection('peers').doc(b));
    batch.delete(_linksOf.doc(b).collection('peers').doc(a));
    await batch.commit();
  }

  @override
  Future<bool> hasLink(String a, String b) async => (await _links.doc(canonicalKey(a, b)).get()).exists;
}
