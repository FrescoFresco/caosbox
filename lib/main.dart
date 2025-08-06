// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'src/filters.dart';
import 'src/widgets/quick_add.dart';
import 'src/widgets/chips_panel.dart';
import 'src/widgets/item_card.dart';
import 'src/widgets/links_block.dart';
import 'src/widgets/info_modal.dart';

void main() async {
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

// +——— MODELS & SyncMixin ——————————————————————————————————+
mixin FirestoreSync {
  final _db = FirebaseFirestore.instance;
  void startSync(void Function(QuerySnapshot<Map<String, dynamic>>) onUpdate) {
    FirebaseAuth.instance.userChanges().listen((u) {
      if (u != null) {
        _db.collection('items').where('uid', isEqualTo: u.uid).snapshots().listen(onUpdate);
      }
    });
  }
  Future<void> syncAdd(String id, Map<String, dynamic> d) => _db.collection('items').doc(id).set(d);
  Future<void> syncUpdate(String id, Map<String, dynamic> d) => _db.collection('items').doc(id).update(d);
}

enum ItemType { idea, action }
enum ItemStatus { normal, completed, archived }

class Item {
  final String id, text;
  final ItemType type;
  final ItemStatus status;
  final DateTime createdAt, modifiedAt;
  final int statusChanges;
  Item(this.id, this.text, this.type, [this.status = ItemStatus.normal, DateTime? c, DateTime? m, this.statusChanges = 0])
    : createdAt = c ?? DateTime.now(), modifiedAt = m ?? DateTime.now();
  Item copyWith({String? text, ItemStatus? status}) => Item(
    id, text ?? this.text, type, status ?? this.status, createdAt, DateTime.now(), this.statusChanges + ((status!=null && status!=this.status)?1:0)
  );
}

extension DateFmt on DateTime {
  String two(int n) => n.toString().padLeft(2,'0');
  String get f => '${two(day)}/${two(month)}/$year ${two(hour)}:${two(minute)}';
}

extension StatusName on ItemStatus {
  String get name => switch(this){
    ItemStatus.normal => 'Normal',
    ItemStatus.completed => 'Completado ✓',
    ItemStatus.archived => 'Archivado 📁'
  };
}

// +——— AppState ——————————————————————————————————————————————————+
class AppState extends ChangeNotifier with FirestoreSync {
  final Map<ItemType,List<Item>> _items = {ItemType.idea:[], ItemType.action:[]};
  final Map<String,Set<String>> _links = {};
  final Map<String,String> _notes = {};
  final Map<String,Item> _cache = {};
  final Map<ItemType,int> _cnt = {ItemType.idea:0, ItemType.action:0};

  AppState() { startSync(_onRemoteUpdate); }

  void _onRemoteUpdate(QuerySnapshot<Map<String,dynamic>> snap){
    _items[ItemType.idea]=[]; _items[ItemType.action]=[];
    _links.clear(); _notes.clear(); _cache.clear();
    for(var doc in snap.docs){
      final d=doc.data();
      final it=Item(
        doc.id,
        d['text'] as String,
        ItemType.values.byName(d['type'] as String),
        ItemStatus.values.byName(d['status'] as String),
        (d['createdAt'] as Timestamp).toDate(),
        (d['modifiedAt'] as Timestamp).toDate(),
        d['statusChanges'] as int,
      );
      _items[it.type]!.add(it);
      _links[it.id]=Set<String>.from(d['links'] as List<dynamic>? ?? []);
      _notes[it.id]=d['note'] as String? ?? '';
      _cache[it.id]=it;
    }
    notifyListeners();
  }

  List<Item> items(ItemType t) => List.unmodifiable(_items[t]!);
  List<Item> get all => _items.values.expand((e)=>e).toList();
  Set<String> links(String id) => _links[id] ?? {};
  String note(String id) => _notes[id] ?? '';
  Item? getItem(String id) => _cache[id];

  void setNote(String id,String v){
    _notes[id]=v; notifyListeners();
    syncUpdate(id,{'note':v});
  }
  void add(ItemType t,String text){
    final v=text.trim(); if(v.isEmpty) return;
    _cnt[t]=(_cnt[t]??0)+1;
    final id='${t==ItemType.idea?'B1':'B2'}${_cnt[t]!.toString().padLeft(3,'0')}';
    final it=Item(id,v,t);
    _items[t]!.insert(0,it); _cache[id]=it; notifyListeners();
    syncAdd(id,{
      'uid':FirebaseAuth.instance.currentUser!.uid,
      'text':it.text,'type':it.type.name,'status':it.status.name,
      'createdAt':it.createdAt,'modifiedAt':it.modifiedAt,
      'statusChanges':it.statusChanges,'links':[],'note':'',
    });
  }
  bool _up(String id,Item Function(Item)fn){
    final it=_cache[id]; if(it==null) return false;
    final list=_items[it.type]!;
    final i=list.indexWhere((e)=>e.id==id); if(i<0) return false;
    final ni=fn(it);
    list[i]=ni; _cache[id]=ni; notifyListeners();
    syncUpdate(id,{
      'text':ni.text,'status':ni.status.name,
      'modifiedAt':ni.modifiedAt,'statusChanges':ni.statusChanges,
      'links':links(id).toList(),
    });
    return true;
  }
  bool setStatus(String id,ItemStatus s) => _up(id,(it)=>it.copyWith(status:s));
  bool updateText(String id,String t) => _up(id,(it)=>it.copyWith(text:t));
  void toggleLink(String a,String b){
    if(a==b||_cache[a]==null||_cache[b]==null) return;
    final sa=_links.putIfAbsent(a,()=>{}), sb=_links.putIfAbsent(b,()=>{});
    if(sa.remove(b)) sb.remove(a); else{sa.add(b);sb.add(a);}
    notifyListeners();
    syncUpdate(a,{'links':links(a).toList()});
    syncUpdate(b,{'links':links(b).toList()});
  }
}

// +——— The App ——————————————————————————————————————————————————+
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override Widget build(BuildContext c) => MaterialApp(
    theme: ThemeData(useMaterial3:true), home: const AuthGate(),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override Widget build(BuildContext c) => StreamBuilder<User?>(
    stream: FirebaseAuth.instance.userChanges(),
    builder: (_,snap){
      if(snap.connectionState==ConnectionState.waiting){
        return const Scaffold(body: Center(child:CircularProgressIndicator()));
      }
      if(!snap.hasData){
        return SignInScreen(
          providers:[
            EmailAuthProvider(),
            GoogleProvider(clientId:'1087718443702-n9856kennjfbunkb0hc26gntrljhnsrs.apps.googleusercontent.com'),
          ],
          actions:[
            AuthStateChangeAction<SignedIn>((ctx,st){
              Navigator.of(ctx).pushReplacement(MaterialPageRoute(builder:(ctx)=>const CaosBox()));
            }),
          ],
        );
      }
      return const CaosBox();
    },
  );
}

class CaosBox extends StatefulWidget {
  const CaosBox({super.key});
  @override State<CaosBox> createState() => _CaosBoxState();
}
class _CaosBoxState extends State<CaosBox> {
  final st=AppState();
  @override Widget build(BuildContext c) => AnimatedBuilder(
    animation:st,builder:(_,__)=>DefaultTabController(
      length:blocks.length,
      child:Scaffold(
        appBar:AppBar(
          title:const Text('CaosBox'),
          bottom:TabBar(tabs:[
            for(final b in blocks)Tab(icon:Icon(b.icon),text:b.label)
          ]),
        ),
        body:SafeArea(child:TabBarView(children:[
          for(final b in blocks)
            if(b.type!=null)GenericScreen(b:b,st:st)
            else b.custom!(c,st)
        ])),
      ),
    ),
  );
}
