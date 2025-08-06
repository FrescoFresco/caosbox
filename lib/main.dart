// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

// ===== FIRESTORE SYNC MIXIN =====
mixin FirestoreSync {
  final _db = FirebaseFirestore.instance;

  void startSync(void Function(QuerySnapshot<Map<String, dynamic>>) onUpdate) {
    FirebaseAuth.instance.userChanges().listen((user) {
      if (user != null) {
        _db
            .collection('items')
            .where('uid', isEqualTo: user.uid)
            .snapshots()
            .listen(onUpdate);
      }
    });
  }

  Map<String, dynamic> toMap(Item it, Set<String> links, String note) => {
        'uid': FirebaseAuth.instance.currentUser!.uid,
        'text': it.text,
        'type': it.type.name,
        'status': it.status.name,
        'createdAt': it.createdAt,
        'modifiedAt': it.modifiedAt,
        'statusChanges': it.statusChanges,
        'links': links.toList(),
        'note': note,
      };

  Future<void> syncAdd(Item it, Set<String> links, String note) =>
      _db.collection('items').doc(it.id).set(toMap(it, links, note));

  Future<void> syncUpdate(String id, Map<String, dynamic> data) =>
      _db.collection('items').doc(id).update(data);
}

// ===== MODELS & ENUMS =====
enum ItemType { idea, action }
enum ItemStatus { normal, completed, archived }
enum FilterMode { off, include, exclude }
enum FilterKey { completed, archived, hasLinks }

class Item {
  final String id, text;
  final ItemType type;
  final ItemStatus status;
  final DateTime createdAt, modifiedAt;
  final int statusChanges;

  Item(this.id, this.text, this.type,
      [this.status = ItemStatus.normal,
      DateTime? c,
      DateTime? m,
      this.statusChanges = 0])
      : createdAt = c ?? DateTime.now(),
        modifiedAt = m ?? DateTime.now();

  Item copyWith({ItemStatus? status}) {
    final ns = status ?? this.status;
    final chg = ns != this.status;
    return Item(
      id,
      text,
      type,
      ns,
      createdAt,
      chg ? DateTime.now() : modifiedAt,
      chg ? statusChanges + 1 : statusChanges,
    );
  }
}

extension DateFmt on DateTime {
  String two(int n) => n.toString().padLeft(2, '0');
  String get f =>
      '${two(day)}/${two(month)}/${year} ${two(hour)}:${two(minute)}';
}

extension StatusName on ItemStatus {
  String get name => switch (this) {
        ItemStatus.normal => 'Normal',
        ItemStatus.completed => 'Completado ✓',
        ItemStatus.archived => 'Archivado 📁'
      };
}

// ===== APP STATE WITH FIRESTORE =====
class AppState extends ChangeNotifier with FirestoreSync {
  final Map<ItemType, List<Item>> _items = {
    ItemType.idea: [],
    ItemType.action: [],
  };
  final Map<String, Set<String>> _links = {};
  final Map<String, String> _notes = {};
  final Map<String, Item> _cache = {};

  AppState() {
    startSync(_onRemoteUpdate);
  }

  void _onRemoteUpdate(QuerySnapshot<Map<String, dynamic>> snap) {
    _items[ItemType.idea] = [];
    _items[ItemType.action] = [];
    _links.clear();
    _notes.clear();
    _cache.clear();
    for (var doc in snap.docs) {
      final d = doc.data();
      final it = Item(
        doc.id,
        d['text'] as String,
        ItemType.values.byName(d['type'] as String),
        ItemStatus.values.byName(d['status'] as String),
        (d['createdAt'] as Timestamp).toDate(),
        (d['modifiedAt'] as Timestamp).toDate(),
        d['statusChanges'] as int,
      );
      _items[it.type]!.add(it);
      _links[it.id] = Set<String>.from(d['links'] as List<dynamic>? ?? []);
      _notes[it.id] = d['note'] as String? ?? '';
      _cache[it.id] = it;
    }
    notifyListeners();
  }

  String note(String id) => _notes[id] ?? '';
  void setNote(String id, String v) {
    _notes[id] = v;
    notifyListeners();
    syncUpdate(id, {'note': v});
  }

  List<Item> items(ItemType t) => List.unmodifiable(_items[t]!);
  List<Item> get all => _items.values.expand((e) => e).toList();
  Set<String> links(String id) => _links[id] ?? {};
  Item? getItem(String id) => _cache[id];

  void add(ItemType t, String text) {
    final v = text.trim();
    if (v.isEmpty) return;
    final prefix = t == ItemType.idea ? 'B1' : 'B2';
    final id = '$prefix${(_items[t]!.length + 1).toString().padLeft(3, '0')}';
    final it = Item(id, v, t);
    _items[t]!.insert(0, it);
    _cache[id] = it;
    notifyListeners();
    syncAdd(it, links(id), note(id));
  }

  bool _up(String id, Item Function(Item) fn) {
    final it = _cache[id];
    if (it == null) return false;
    final list = _items[it.type]!;
    final idx = list.indexWhere((e) => e.id == id);
    if (idx < 0) return false;
    final ni = fn(it);
    list[idx] = ni;
    _cache[id] = ni;
    notifyListeners();
    syncUpdate(id, {
      'text': ni.text,
      'status': ni.status.name,
      'modifiedAt': ni.modifiedAt,
      'statusChanges': ni.statusChanges,
      'links': links(id).toList(),
    });
    return true;
  }

  bool setStatus(String id, ItemStatus s) => _up(id, (it) => it.copyWith(status: s));
  bool updateText(String id, String t) => _up(id, (it) => it.copyWith()..text);

  void toggleLink(String a, String b) {
    if (a == b || _cache[a] == null || _cache[b] == null) return;
    final sa = _links.putIfAbsent(a, () => {});
    final sb = _links.putIfAbsent(b, () => {});
    if (sa.remove(b)) sb.remove(a);
    else {
      sa.add(b);
      sb.add(a);
    }
    notifyListeners();
    syncUpdate(a, {'links': links(a).toList()});
    syncUpdate(b, {'links': links(b).toList()});
  }
}

// ===== UI & APP =====
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBbpkoc4YlqfuYyM2TYASidFMOpeN9v2e4",
      authDomain: "caosbox-ef75b.firebaseapp.com",
      projectId: "caosbox-ef75b",
      storageBucket: "caosbox-ef75b.firebasestorage.app",
      messagingSenderId: "1087718443702",
      appId: "1:1087718443702:web:53c05e5ca672de14b5f417",
      measurementId: "G-8C1RD6K5Q5",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override Widget build(BuildContext context) => MaterialApp(
    theme: ThemeData(useMaterial3: true),
    home: const AuthGate(),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override Widget build(BuildContext context) {
    return StreamBuilder<User?>(stream: FirebaseAuth.instance.userChanges(), builder: (_,snap){
      if (snap.connectionState==ConnectionState.waiting) {
        return const Scaffold(body: Center(child:CircularProgressIndicator()));
      }
      if (!snap.hasData) {
        return SignInScreen(
          providers:[
            EmailAuthProvider(),
            GoogleProvider(clientId:'1087718443702-n9856kennjfbunkb0hc26gntrljhnsrs.apps.googleusercontent.com'),
          ],
          actions:[
            AuthStateChangeAction<SignedIn>((ctx,st){
              Navigator.of(ctx).pushReplacement(MaterialPageRoute(builder:_=>const CaosBox()));
            })
          ],
        );
      }
      return const CaosBox();
    });
  }
}

class CaosBox extends StatelessWidget {
  const CaosBox({super.key});
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('CaosBox')),
    body: const Center(child: Text('Tu app aquí')),
  );
}
