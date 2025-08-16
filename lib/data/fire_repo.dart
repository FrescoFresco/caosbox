import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:caosbox/core/models/enums.dart';
import 'package:caosbox/core/models/item.dart';

/// users/{uid}
///   counters: {idea, action}
///   items/{id} -> {id,type,status,text,createdAt,modifiedAt,statusChanges,note}
///   links/{a|b} -> {a,b}     (no dirigido)
class FireRepo {
  FireRepo(this._db, this.uid);
  final FirebaseFirestore _db;
  final String uid;

  DocumentReference<Map<String, dynamic>> get _user =>
      _db.collection('users').doc(uid);
  CollectionReference<Map<String, dynamic>> get _items =>
      _user.collection('items');
  CollectionReference<Map<String, dynamic>> get _links =>
      _user.collection('links');

  StreamSubscription? _itemsSub, _linksSub, _userSub;
  void dispose() { _itemsSub?.cancel(); _linksSub?.cancel(); _userSub?.cancel(); }

  static String _pairKey(String a, String b) =>
      (a.compareTo(b) <= 0) ? '$a|$b' : '$b|$a';

  static Map<String, dynamic> _itemToMap(Item it, {String? note}) => {
        'id': it.id,
        'type': it.type.name,
        'status': it.status.name,
        'text': it.text,
        'createdAt': Timestamp.fromDate(it.createdAt),
        'modifiedAt': Timestamp.fromDate(it.modifiedAt),
        'statusChanges': it.statusChanges,
        if (note != null) 'note': note,
      };

  static Item _itemFromMap(Map<String, dynamic> m) {
    final type = (m['type'] == 'idea') ? ItemType.idea : ItemType.action;
    final status = switch (m['status']) {
      'completed' => ItemStatus.completed,
      'archived'  => ItemStatus.archived,
      _           => ItemStatus.normal,
    };
    DateTime _ts(dynamic v) =>
        v is Timestamp ? v.toDate() : (DateTime.tryParse('$v') ?? DateTime.now());
    return Item(
      m['id'] ?? '',
      m['text'] ?? '',
      type,
      status: status,
      createdAt: _ts(m['createdAt']),
      modifiedAt: _ts(m['modifiedAt']),
      statusChanges: (m['statusChanges'] is int) ? m['statusChanges'] : 0,
    );
  }

  void subscribe(void Function({
    required List<Item> items,
    required Map<String, Set<String>> links,
    required Map<ItemType, int> counters,
    required Map<String, String> notes,
  }) onData) {
    List<Item> curItems = [];
    Map<String, Set<String>> curLinks = {};
    Map<ItemType, int> curCounters = {ItemType.idea: 0, ItemType.action: 0};
    Map<String, String> curNotes = {};

    void emit() => onData(
      items: curItems, links: curLinks, counters: curCounters, notes: curNotes);

    _itemsSub = _items.snapshots().listen((snap) {
      curItems = [for (final d in snap.docs) _itemFromMap(d.data())]
        ..sort((a,b)=>b.createdAt.compareTo(a.createdAt));
      curNotes = {
        for (final d in snap.docs)
          if (d.data().containsKey('note')) d['id']: '${d['note']}'
      };
      emit();
    });

    _linksSub = _links.snapshots().listen((snap) {
      curLinks = {};
      for (final d in snap.docs) {
        final m = d.data(); final a='${m['a']}', b='${m['b']}';
        curLinks.putIfAbsent(a, ()=> <String>{}).add(b);
        curLinks.putIfAbsent(b, ()=> <String>{}).add(a);
      }
      emit();
    });

    _userSub = _user.snapshots().listen((d) {
      final m = d.data();
      final idea   = (m?['counters']?['idea']   ?? 0) as int;
      final action = (m?['counters']?['action'] ?? 0) as int;
      curCounters = {ItemType.idea: idea, ItemType.action: action};
      emit();
    });
  }

  Future<void> addItem(ItemType t, String text) async {
    final pref = (t == ItemType.idea) ? 'B1' : 'B2';
    await _db.runTransaction((tx) async {
      final u = await tx.get(_user);
      final curIdea   = (u.data()?['counters']?['idea']   ?? 0) as int;
      final curAction = (u.data()?['counters']?['action'] ?? 0) as int;

      final next = (t == ItemType.idea) ? curIdea + 1 : curAction + 1;
      final id = '$pref${next.toString().padLeft(3, '0')}';

      final now = DateTime.now();
      tx.set(_items.doc(id), _itemToMap(Item(id, text, t,
        status: ItemStatus.normal, createdAt: now, modifiedAt: now, statusChanges: 0)));

      tx.set(_user, {
        'counters': {
          'idea':   (t == ItemType.idea)   ? next : curIdea,
          'action': (t == ItemType.action) ? next : curAction,
        }
      }, SetOptions(merge: true));
    });
  }

  Future<void> updateText(String id, String text) =>
      _items.doc(id).update({'text': text, 'modifiedAt': Timestamp.now()});

  Future<void> setStatus(String id, ItemStatus s, int statusChanges) =>
      _items.doc(id).update({
        'status': s.name,
        'statusChanges': statusChanges,
        'modifiedAt': Timestamp.now(),
      });

  Future<void> setNote(String id, String v) =>
      _items.doc(id).set({'note': v, 'modifiedAt': Timestamp.now()}, SetOptions(merge: true));

  Future<void> toggleLink(String a, String b) async {
    if (a == b) return;
    final key = _pairKey(a, b);
    final ref = _links.doc(key);
    final snap = await ref.get();
    if (snap.exists) {
      await ref.delete();
    } else {
      await ref.set({'a': a, 'b': b});
    }
  }
}
