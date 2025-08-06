// lib/main.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<void> syncAdd(String id, Map<String, dynamic> data) =>
      _db.collection('items').doc(id).set(data);

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

  Item(this.id, this.text, this.type, [
    this.status = ItemStatus.normal,
    DateTime? c,
    DateTime? m,
    this.statusChanges = 0,
  ])  : createdAt = c ?? DateTime.now(),
        modifiedAt = m ?? DateTime.now();

  Item copyWith({
    String? text,
    ItemStatus? status,
    DateTime? modifiedAt,
    int? statusChanges,
  }) {
    return Item(
      id,
      text ?? this.text,
      type,
      status ?? this.status,
      createdAt,
      modifiedAt ?? DateTime.now(),
      statusChanges ?? this.statusChanges,
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
  final Map<ItemType, int> _cnt = {ItemType.idea: 0, ItemType.action: 0};

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
    _cnt[t] = (_cnt[t] ?? 0) + 1;
    final prefix = t == ItemType.idea ? 'B1' : 'B2';
    final id = '$prefix${_cnt[t]!.toString().padLeft(3, '0')}';
    final it = Item(id, v, t);
    _items[t]!.insert(0, it);
    _cache[id] = it;
    notifyListeners();
    syncAdd(id, {
      'uid': FirebaseAuth.instance.currentUser!.uid,
      'text': it.text,
      'type': it.type.name,
      'status': it.status.name,
      'createdAt': it.createdAt,
      'modifiedAt': it.modifiedAt,
      'statusChanges': it.statusChanges,
      'links': [],
      'note': '',
    });
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
  bool updateText(String id, String t) =>
      _up(id, (it) => it.copyWith(text: t, modifiedAt: DateTime.now()));

  void toggleLink(String a, String b) {
    if (a == b || _cache[a] == null || _cache[b] == null) return;
    final sa = _links.putIfAbsent(a, () => {});
    final sb = _links.putIfAbsent(b, () => {});
    if (sa.remove(b)) {
      sb.remove(a);
    } else {
      sa.add(b);
      sb.add(a);
    }
    notifyListeners();
    syncUpdate(a, {'links': links(a).toList()});
    syncUpdate(b, {'links': links(b).toList()});
  }
}

// ===== UI COMPONENTS =====

class QuickAdd extends StatefulWidget {
  final ItemType type;
  final AppState st;
  const QuickAdd({super.key, required this.type, required this.st});
  @override State<QuickAdd> createState() => _QuickAddState();
}

class _QuickAddState extends State<QuickAdd> {
  final _ctrl = TextEditingController();
  @override Widget build(BuildContext context) {
    final cfg = widget.type == ItemType.idea
        ? ItemTypeCfg(prefix: 'B1', icon: Icons.lightbulb, label: 'Ideas', hint: 'Escribe tu idea...')
        : ItemTypeCfg(prefix: 'B2', icon: Icons.assignment, label: 'Acciones', hint: 'Describe la acción...');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Icon(cfg.icon),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _ctrl,
              decoration: InputDecoration(
                hintText: cfg.hint,
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (_) => _add(),
            ),
          ),
          IconButton(icon: const Icon(Icons.add), onPressed: _add),
        ]),
      ),
    );
  }
  void _add() {
    if (_ctrl.text.trim().isNotEmpty) {
      widget.st.add(widget.type, _ctrl.text);
      _ctrl.clear();
    }
  }
  @override void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}

class ChipsPanel extends StatelessWidget {
  final FilterSet set;
  final VoidCallback onUpdate;
  final Map<FilterKey, FilterMode>? defaults;
  const ChipsPanel({super.key, required this.set, required this.onUpdate, this.defaults});
  @override Widget build(BuildContext ctx) {
    Widget chip(FilterKey k, String label) {
      final m = set.modes[k]!;
      final on = m != FilterMode.off;
      final col = on
          ? (m == FilterMode.include ? Colors.green : Colors.red).withOpacity(0.3)
          : null;
      final txt = m == FilterMode.exclude ? '⊘$label' : label;
      return FilterChip(label: Text(txt), selected: on, selectedColor: col, onSelected: (_) {
        set.cycle(k);
        onUpdate();
      });
    }
    return Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(
        controller: set.text,
        onChanged: (_) => onUpdate(),
        decoration: const InputDecoration(hintText: 'Buscar...', prefixIcon: Icon(Icons.search), isDense: true),
      ),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 6, children: [
        chip(FilterKey.completed, '✓'),
        chip(FilterKey.archived, '↓'),
        chip(FilterKey.hasLinks, '~'),
        if (set.hasActive)
          IconButton(
            icon: const Icon(Icons.clear, size: 16),
            onPressed: () {
              if (defaults != null) set.setDefaults(defaults!);
              else set.clear();
              onUpdate();
            },
          ),
      ]),
    ]);
  }
}

class ItemCard extends StatelessWidget {
  final Item it; final AppState st;
  final bool ex, showL, cbL, cbR, ck;
  final VoidCallback onT, onInfo;
  final VoidCallback? onTapCb;
  const ItemCard({
    super.key,
    required this.it,
    required this.st,
    required this.ex,
    required this.onT,
    required this.onInfo,
    this.showL = true,
    this.cbL = false,
    this.cbR = false,
    this.ck = false,
    this.onTapCb,
  });
  @override Widget build(BuildContext c) {
    final m = {
      ItemStatus.completed: {'icon': Icons.check, 'color': Colors.green},
      ItemStatus.archived: {'icon': Icons.archive, 'color': Colors.grey},
    }[it.status];
    return Dismissible(
      key: Key('${it.id}-${it.status}'),
      confirmDismiss: (d) => Behavior.swipe(d, it.status, (s) => st.setStatus(it.id, s)),
      background: Behavior.bg(false),
      secondaryBackground: Behavior.bg(true),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: GestureDetector(
          onLongPress: onInfo,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (cbL) Checkbox(value: ck, onChanged: onTapCb != null ? (_) => onTapCb!() : null),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  if (m != null) Icon(m['icon'] as IconData, color: m['color'] as Color, size: 16),
                  if (showL && st.links(it.id).isNotEmpty)
                    const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.link, color: Colors.blue, size: 16)),
                  const SizedBox(width: 6),
                  Flexible(child: Text(it.id, style: const TextStyle(fontSize: 12, color: Colors.grey))),
                  const Spacer(),
                ]),
                const SizedBox(height: 6),
                InkWell(onTap: onT, child: Text(it.text, maxLines: ex ? null : 1, overflow: ex ? null : TextOverflow.ellipsis)),
              ])),
              if (cbR) Checkbox(value: ck, onChanged: onTapCb != null ? (_) => onTapCb!() : null),
            ]),
          ),
        ),
      ),
    );
  }
}

class Behavior {
  static Future<bool> swipe(DismissDirection d, ItemStatus s, Function(ItemStatus) on) async {
    on(d == DismissDirection.startToEnd
        ? (s == ItemStatus.completed ? ItemStatus.normal : ItemStatus.completed)
        : (s == ItemStatus.archived ? ItemStatus.normal : ItemStatus.archived));
    return false;
  }
  static Widget bg(bool sec) => Container(
        color: (sec ? Colors.grey : Colors.green).withOpacity(0.2),
        child: Align(
          alignment: sec ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Icon(sec ? Icons.archive : Icons.check, color: sec ? Colors.grey : Colors.green),
          ),
        ),
      );
}

void showInfoModal(BuildContext c, Item it, AppState s) {
  showModalBottomSheet(
    context: c,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => InfoModal(id: it.id, st: s),
  );
}

class InfoModal extends StatefulWidget {
  final String id; final AppState st;
  const InfoModal({super.key, required this.id, required this.st});
  @override State<InfoModal> createState() => _InfoModalState();
}
class _InfoModalState extends State<InfoModal> {
  late final TextEditingController ed;
  late final TextEditingController note;
  Timer? _deb, _debN;
  @override void initState() {
    super.initState();
    ed = TextEditingController(text: widget.st.getItem(widget.id)!.text);
    note = TextEditingController(text: widget.st.note(widget.id));
  }
  @override void dispose() {
    _deb?.cancel();
    _debN?.cancel();
    ed.dispose();
    note.dispose();
    super.dispose();
  }
  @override Widget build(BuildContext c) {
    return AnimatedBuilder(animation: widget.st, builder: (ctx, _) {
      final cur = widget.st.getItem(widget.id)!;
      final linked = widget.st.all.where((i) => widget.st.links(widget.id).contains(i.id)).toList();
      final latest = widget.st.note(widget.id);
      if (note.text != latest) {
        note.text = latest;
        note.selection = TextSelection.collapsed(offset: note.text.length);
      }
      return FractionallySizedBox(
        heightFactor: 0.9,
        child: DefaultTabController(length: 4, child: Material(child: Column(children: [
          Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            Icon(cur.type == ItemType.idea ? Icons.lightbulb : Icons.assignment),
            const SizedBox(width: 8),
            Expanded(child: Text('${cur.type.name} • ${cur.id}', style: const TextStyle(fontSize:18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
            if (cur.status != ItemStatus.normal)
              Padding(
                padding: const EdgeInsets.only(right:4),
                child: Chip(label: Text(cur.status.name), visualDensity: VisualDensity.compact),
              ),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
          ])),
          const TabBar(tabs: [
            Tab(icon: Icon(Icons.description), text: 'Contenido'),
            Tab(icon: Icon(Icons.link), text: 'Relacionado'),
            Tab(icon: Icon(Icons.info), text: 'Info'),
            Tab(icon: Icon(Icons.timer), text: 'Tiempo'),
          ]),
          Expanded(child: TabBarView(children: [
            // Contenido
            Padding(padding: const EdgeInsets.all(16), child: TextField(
              controller: ed,
              minLines: 3,
              maxLines: 10,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Editar contenido'),
              onChanged: (t) {
                _deb?.cancel();
                _deb = Timer(const Duration(milliseconds:250), () => widget.st.updateText(cur.id, t));
              },
            )),
            // Relacionado
            linked.isEmpty
              ? const Center(child: Text('Sin relaciones', style: TextStyle(color:Colors.grey)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: linked.map((li) {
                    final ck = widget.st.links(cur.id).contains(li.id);
                    return CheckboxListTile(
                      title: Text(li.id),
                      value: ck,
                      onChanged: (_) => widget.st.toggleLink(cur.id, li.id),
                    );
                  }).toList(),
                ),
            // Info
            ListView(padding: const EdgeInsets.all(16), children: [
              _infoRow('Tipo', cur.type.name),
              _infoRow('Creado', cur.createdAt.f),
              _infoRow('Modificado', cur.modifiedAt.f),
              _infoRow('Estado', cur.status.name),
              _infoRow('Cambios', cur.statusChanges.toString()),
              _infoRow('Relaciones', linked.length.toString()),
            ]),
            // Tiempo
            Padding(padding: const EdgeInsets.all(16), child: TextField(
              controller: note,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Notas...'),
              onChanged: (t) {
                _debN?.cancel();
                _debN = Timer(const Duration(milliseconds:250), () => widget.st.setNote(cur.id, t));
              },
            )),
          ])),
        ]))),
      );
    });
  }
}
Widget _infoRow(String label, String value) => Padding(
  padding: const EdgeInsets.symmetric(vertical:6),
  child: Row(children: [
    SizedBox(width:120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
    Expanded(child: Text(value)),
  ]),
);

// ===== BLOQUES / PANTALLAS =====

class ItemTypeCfg { final String prefix, hint, label; final IconData icon;
  const ItemTypeCfg({required this.prefix, required this.icon, required this.label, required this.hint});
}
typedef BuilderFn = Widget Function(BuildContext, AppState);

class Block {
  final String id; final IconData icon; final String label;
  final ItemType? type; final ItemTypeCfg? cfg;
  final Map<FilterKey,FilterMode> defaults; final BuilderFn? custom;
  const Block.item({required this.id,required this.icon,required this.label,required this.type,required this.cfg,this.defaults=const{}}): custom=null;
  const Block.custom({required this.id,required this.icon,required this.label,required this.custom}): type=null,cfg=null,defaults=const{};
}

final ideasCfg = ItemTypeCfg(prefix:'B1',icon:Icons.lightbulb,label:'Ideas',hint:'Escribe tu idea...');
final actionsCfg = ItemTypeCfg(prefix:'B2',icon:Icons.assignment,label:'Acciones',hint:'Describe la acción...');
final blocks = <Block>[
  Block.item(id:'ideas',icon:ideasCfg.icon,label:ideasCfg.label,type:ItemType.idea,cfg:ideasCfg),
  Block.item(id:'actions',icon:actionsCfg.icon,label:actionsCfg.label,type:ItemType.action,cfg:actionsCfg),
  Block.custom(id:'links',icon:Icons.link,label:'Enlaces',custom:(ctx,st)=>LinksBlock(st:st)),
];

class GenericScreen extends StatefulWidget {
  final Block b; final AppState st;
  const GenericScreen({super.key,required this.b,required this.st});
  @override State<GenericScreen> createState() => _GenericScreenState();
}
class _GenericScreenState extends State<GenericScreen> with AutomaticKeepAliveClientMixin {
  final _f = FilterSet(); final _ex = <String>{}; late final TextEditingController _c;
  @override void initState() { super.initState(); _c = TextEditingController(); _f.setDefaults(widget.b.defaults); }
  @override void dispose() { _c.dispose(); _f.dispose(); super.dispose(); }
  void _r() => setState((){});
  @override bool get wantKeepAlive => true;
  @override Widget build(BuildContext ctx) {
    super.build(ctx);
    final t = widget.b.type!;
    final cfg = widget.b.cfg!;
    final filtered = FilterEngine.apply(widget.st.items(t),widget.st,_f);
    return Padding(padding: const EdgeInsets.all(12),child: Column(children:[
      QuickAdd(type:t,st:widget.st),
      const SizedBox(height:12),
      Flexible(fit:FlexFit.loose,child:SingleChildScrollView(child:ChipsPanel(set:_f,onUpdate:_r,defaults:widget.b.defaults))),
      const SizedBox(height:8),
      Expanded(child:ListView.builder(itemCount:filtered.length,itemBuilder:(_,i){
        final it = filtered[i], open = _ex.contains(it.id);
        return ItemCard(it:it,st:widget.st,ex:open,onT:(){
          if(open) _ex.remove(it.id); else _ex.add(it.id);
          _r();
        },onInfo:()=>showInfoModal(ctx,it,widget.st));
      })),
    ]));
  }
}

class LinksBlock extends StatefulWidget {
  final AppState st;
  const LinksBlock({super.key,required this.st});
  @override State<LinksBlock> createState() => _LinksBlockState();
}
class _LinksBlockState extends State<LinksBlock> with AutomaticKeepAliveClientMixin {
  final l = FilterSet(), r = FilterSet(); String? sel;
  @override void dispose(){ l.dispose(); r.dispose(); super.dispose(); }
  Widget panel({required String t, required Widget chips, required Widget body})=>Padding(
    padding: const EdgeInsets.symmetric(horizontal:12),
    child:Column(children:[
      Padding(padding:const EdgeInsets.only(bottom:8),child:Align(alignment:Alignment.centerLeft,child:Text(t,style:const TextStyle(fontWeight:FontWeight.bold)))),
      Flexible(fit:FlexFit.loose,child:SingleChildScrollView(child:chips)),
      const SizedBox(height:8),
      Expanded(child:body),
    ]),
  );
  @override bool get wantKeepAlive => true;
  @override Widget build(BuildContext c){
    super.build(c);
    final st = widget.st;
    final li = FilterEngine.apply(st.all,st,l);
    final base = st.all.where((i)=>i.id!=sel).toList();
    final ri = FilterEngine.apply(base,st,r);
    return Column(children:[
      const Padding(padding:EdgeInsets.fromLTRB(12,12,12,8),child:Text('Conectar elementos',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold))),
      Expanded(child:OrientationBuilder(builder:(ctx,o)=>o==Orientation.portrait
        ? Column(children:[
            Expanded(child:panel(t:'Seleccionar:',chips:ChipsPanel(set:l,onUpdate:()=>setState((){})),body:ListView.builder(itemCount:li.length,itemBuilder:(_,i){
              final it = li[i];
              return ItemCard(it:it,st:st,ex:false,onT:(){},onInfo:()=>showInfoModal(c,it,st),cbR:true,ck:sel==it.id,onTapCb:()=>setState(()=>sel = sel==it.id?null:it.id));
            }))),
            const Divider(height:1),
            Expanded(child:panel(t:'Conectar con:',chips:ChipsPanel(set:r,onUpdate:()=>setState((){})),body: sel==null ? const Center(child:Text('Selecciona un elemento')) :
              ListView.builder(itemCount:ri.length,itemBuilder:(_,i){
                final it = ri[i], ck = st.links(sel!).contains(it.id);
                return ItemCard(it:it,st:st,ex:false,onT:(){},onInfo:()=>showInfoModal(c,it,st),cbR:true,ck:ck,onTapCb:()=>setState(()=>st.toggleLink(sel!,it.id)));
              }))
          ])
        : Row(children:[
            Expanded(child:panel(t:'Seleccionar:',chips:ChipsPanel(set:l,onUpdate:()=>setState((){})),body:ListView.builder(itemCount:li.length,itemBuilder:(_,i){
              final it = li[i];
              return ItemCard(it:it,st:st,ex:false,onT:(){},onInfo:()=>showInfoModal(c,it,st),cbR:true,ck:sel==it.id,onTapCb:()=>setState(()=>sel = sel==it.id?null:it.id));
            }))),
            const VerticalDivider(width:1),
            Expanded(child:panel(t:'Conectar con:',chips:ChipsPanel(set:r,onUpdate:()=>setState((){})),body: sel==null ? const Center(child:Text('Selecciona un elemento')) :
              ListView.builder(itemCount:ri.length,itemBuilder:(_,i){
                final it = ri[i], ck = st.links(sel!).contains(it.id);
                return ItemCard(it:it,st:st,ex:false,onT:(){},onInfo:()=>showInfoModal(c,it,st),cbR:true,ck:ck,onTapCb:()=>setState(()=>st.toggleLink(sel!,it.id)));
              }))
        ]))
    ]);
  }
}

// ===== MAIN, AUTH & APP =====

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
      if (snap.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child:CircularProgressIndicator()));
      }
      if (!snap.hasData) {
        return SignInScreen(
          providers: [
            EmailAuthProvider(),
            GoogleProvider(clientId:'1087718443702-n9856kennjfbunkb0hc26gntrljhnsrs.apps.googleusercontent.com'),
          ],
          actions: [
            AuthStateChangeAction<SignedIn>((ctx,st){
              Navigator.of(ctx).pushReplacement(MaterialPageRoute(builder:(_) => const CaosBox()));
            }),
          ],
        );
      }
      return const CaosBox();
    });
  }
}
