import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ===== FIRESTORE SYNC MIXIN =====
mixin FirestoreSync {
  final _db = FirebaseFirestore.instance;
  void startSync(void Function(QuerySnapshot) onUpdate) {
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
    final ns = status ?? this.status, chg = ns != this.status;
    return Item(id, text, type, ns, createdAt,
        chg ? DateTime.now() : modifiedAt, chg ? statusChanges + 1 : statusChanges);
  }
}

// ===== APP STATE WITH FIRESTORE =====
class AppState extends ChangeNotifier with FirestoreSync {
  final Map<ItemType, List<Item>> _items = {
    ItemType.idea: [],
    ItemType.action: []
  };
  final Map<String, Set<String>> _links = {};
  final Map<ItemType, int> _cnt = {ItemType.idea: 0, ItemType.action: 0};
  final Map<String, Item> _cache = {};
  final Map<String, String> _notes = {};
  AppState() { startSync(_onRemoteUpdate); }
  void _onRemoteUpdate(QuerySnapshot snap) {
    _items[ItemType.idea] = [];
    _items[ItemType.action] = [];
    _links.clear();
    _notes.clear();
    for (var doc in snap.docs) {
      final d = doc.data() as Map<String, dynamic>;
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
    }
    _cache
      ..clear()
      ..addAll({for (var it in all) it.id: it});
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
    _cnt[t] = (_cnt[t] ?? 0) + 1;
    final id = '${t == ItemType.idea ? 'B1' : 'B2'}${_cnt[t]!.toString().padLeft(3,'0')}';
    final it = Item(id, v, t);
    _items[t]!.insert(0, it);
    _cache[id] = it;
    notifyListeners();
    syncAdd(it, links(id), note(id));
  }
  bool _up(String id, Item Function(Item) fn) {
    final it = _cache[id];
    if (it == null) return false;
    final i = _items[it.type]!.indexWhere((e)=>e.id==id);
    if (i<0) return false;
    _items[it.type]![i] = fn(it);
    _cache[id] = _items[it.type]![i];
    notifyListeners();
    return true;
  }
  bool setStatus(String id, ItemStatus s) => _up(id, (it) {
    final ni = it.copyWith(status: s);
    syncUpdate(id, {'status': ni.status.name,'modifiedAt':ni.modifiedAt,'statusChanges':ni.statusChanges});
    return ni;
  });
  bool updateText(String id, String t) => _up(id, (it) {
    final ni = Item(it.id,t,it.type,it.status,it.createdAt,DateTime.now(),it.statusChanges);
    syncUpdate(id, {'text':ni.text,'modifiedAt':ni.modifiedAt});
    return ni;
  });
  void toggleLink(String a, String b) {
    if(a==b||_cache[a]==null||_cache[b]==null) return;
    final sa=_links.putIfAbsent(a,()=>{}), sb=_links.putIfAbsent(b,()=>{});
    if(sa.remove(b)){sb.remove(a);}else{sa.add(b);sb.add(a);}
    notifyListeners();
    syncUpdate(a,{'links':links(a).toList()});
    syncUpdate(b,{'links':links(b).toList()});
  }
}

// ===== UI & APP =====
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: const FirebaseOptions(
    apiKey: "AIzaSyBbpkoc4YlqfuYyM2TYASidFMOpeN9v2e4",
    authDomain: "caosbox-ef75b.firebaseapp.com",
    projectId: "caosbox-ef75b",
    storageBucket: "caosbox-ef75b.firebasestorage.app",
    messagingSenderId: "1087718443702",
    appId: "1:1087718443702:web:53c05e5ca672de14b5f417",
    measurementId: "G-8C1RD6K5Q5",
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override Widget build(BuildContext c) => MaterialApp(
    theme: ThemeData(useMaterial3: true),
    home: const AuthGate(),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override Widget build(BuildContext c) {
    return StreamBuilder<User?>(stream: FirebaseAuth.instance.userChanges(), builder:(_,snap){
      if (snap.connectionState==ConnectionState.waiting) {
        return const Scaffold(body: Center(child:CircularProgressIndicator()));
      }
      if (snap.hasData) return const CaosBox();
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
    });
  }
}

class CaosBox extends StatelessWidget {
  const CaosBox({super.key});
  @override Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:const Text('CaosBox')),
    body:const Center(child:Text('Tu app aquí')),
  );
}
