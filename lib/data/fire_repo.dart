// lib/data/fire_repo.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models.dart';

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

  DocumentReference<Map<String, dynamic>> get _counters =>
      _user.collection('meta').doc('counters');

  /// Stream de TODOS los items (orden creados desc). Filtramos por tipo en cliente.
  Stream<List<Item>> watchItemsAll() {
    return _items.orderBy('createdAt', descending: true).snapshots().map(
      (snap) => snap.docs.map((d) => Item.fromMap(d.data())).toList(),
    );
  }

  /// Stream de links que contengan un id dado (array-contains).
  Stream<Set<String>> watchLinksFor(String idHuman) {
    return _links.where('pair', arrayContains: idHuman).snapshots().map((s) {
      final out = <String>{};
      for (final d in s.docs) {
        final p = List<String>.from(d.data()['pair'] ?? const []);
        if (p.length == 2) {
          final other = p[0] == idHuman ? p[1] : p[0];
          out.add(other);
        }
      }
      return out;
    });
  }

  /// Crea item con contador por tipo → idHuman ej. B1002 / A0042
  Future<String> createItem(ItemType type, String text, {String note = ''}) async {
    final now = DateTime.now();
    final idHuman = await _nextIdHuman(type);
    final data = {
      'idHuman': idHuman,
      'type': type.asString,
      'text': text,
      'note': note,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };
    await _items.doc(idHuman).set(data);
    return idHuman;
  }

  Future<void> updateItem(String idHuman, {String? text, String? note}) async {
    final m = <String, dynamic>{'updatedAt': DateTime.now().toIso8601String()};
    if (text != null) m['text'] = text;
    if (note != null) m['note'] = note;
    await _items.doc(idHuman).update(m);
  }

  Future<void> deleteItem(String idHuman) async {
    // Borra item
    await _items.doc(idHuman).delete();
    // Borra todos los links que lo referencien
    final q = await _links.where('pair', arrayContains: idHuman).get();
    for (final d in q.docs) {
      await _links.doc(d.id).delete();
    }
  }

  /// Conectar / Desconectar par A↔B (toggle)
  Future<void> toggleLink(String a, String b) async {
    if (a == b) return;
    final pair = [a, b]..sort();
    final key = '${pair[0]}|${pair[1]}';
    final ref = _links.doc(key);
    final got = await ref.get();
    if (got.exists) {
      await ref.delete();
    } else {
      await ref.set({
        'pair': pair,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Siguiente correlativo por tipo
  Future<String> _nextIdHuman(ItemType type) async {
    final field = type == ItemType.idea ? 'idea' : 'action';
    return _db.runTransaction((tx) async {
      final snap = await tx.get(_counters);
      final curr = (snap.data()?[field] ?? 0) as int;
      final next = curr + 1;
      tx.set(_counters, {field: next}, SetOptions(merge: true));
      final prefix = type.prefix; // B / A
      final idHuman = '$prefix${next.toString().padLeft(4, '0')}';
      return idHuman;
    });
  }
}
