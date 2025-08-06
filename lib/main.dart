// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

import 'src/models/models.dart';
import 'src/utils/filter_engine.dart';
import 'src/widgets/quick_add.dart';
import 'src/widgets/chips_panel.dart';
import 'src/widgets/item_card.dart';
import 'src/widgets/links_block.dart';
import 'src/widgets/info_modal.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CaosBox',
      theme: ThemeData(useMaterial3: true),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snap.hasData) {
          return SignInScreen(
            providers: [EmailAuthProvider()],
            actions: [
              AuthStateChangeAction((ctx, state) {
                if (state is SignedIn) {
                  Navigator.of(ctx).pushReplacement(
                    MaterialPageRoute(builder: (_) => const CaosBox()),
                  );
                }
              }),
            ],
          );
        }
        return const CaosBox();
      },
    );
  }
}

class AppState extends ChangeNotifier {
  final _items = <ItemType, List<Item>>{
    ItemType.idea: [],
    ItemType.action: [],
  };
  final _links = <String, Set<String>>{};
  final _cnt = <ItemType, int>{ItemType.idea: 0, ItemType.action: 0};
  final _cache = <String, Item>{};
  final _notes = <String, String>{};

  String note(String id) => _notes[id] ?? '';
  void setNote(String id, String v) {
    _notes[id] = v;
    notifyListeners();
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
    _items[t]!.insert(0, Item(id, v, t));
    _reindex();
    notifyListeners();
  }

  bool setStatus(String id, ItemStatus s) {
    return _update(id, (it) => it.copyWith(status: s));
  }

  bool updateText(String id, String t) {
    return _update(id, (it) => Item(it.id, t, it.type, it.status, it.createdAt, DateTime.now(), it.statusChanges));
  }

  void toggleLink(String a, String b) {
    if (a == b || _cache[a] == null || _cache[b] == null) return;
    final sa = _links.putIfAbsent(a, () => <String>{});
    final sb = _links.putIfAbsent(b, () => <String>{});
    if (sa.remove(b)) {
      sb.remove(a);
    } else {
      sa.add(b);
      sb.add(a);
    }
    notifyListeners();
  }

  bool _update(String id, Item Function(Item) transformer) {
    final it = _cache[id];
    if (it == null) return false;
    final list = _items[it.type]!;
    final idx = list.indexWhere((e) => e.id == id);
    if (idx < 0) return false;
    list[idx] = transformer(it);
    _reindex();
    notifyListeners();
    return true;
  }

  void _reindex() {
    _cache
      ..clear()
      ..addAll({for (final it in all) it.id: it});
  }
}

class CaosBox extends StatefulWidget {
  const CaosBox({super.key});
  @override
  State<CaosBox> createState() => _CaosBoxState();
}

class _CaosBoxState extends State<CaosBox> {
  final st = AppState();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: st,
      builder: (_, __) => DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('CaosBox'),
            bottom: const TabBar(tabs: [
              Tab(icon: Icon(Icons.lightbulb), text: 'Ideas'),
              Tab(icon: Icon(Icons.assignment), text: 'Acciones'),
              Tab(icon: Icon(Icons.link), text: 'Enlaces'),
            ]),
          ),
          body: TabBarView(children: [
            GenericScreen(type: ItemType.idea, st: st),
            GenericScreen(type: ItemType.action, st: st),
            LinksBlock(st: st),
          ]),
        ),
      ),
    );
  }
}

class GenericScreen extends StatefulWidget {
  final ItemType type;
  final AppState st;
  const GenericScreen({super.key, required this.type, required this.st});

  @override
  State<GenericScreen> createState() => _GenericScreenState();
}

class _GenericScreenState extends State<GenericScreen>
    with AutomaticKeepAliveClientMixin {
  final _filter = FilterSet();
  final _expanded = <String>{};

  @override
  void initState() {
    super.initState();
    _filter.setDefaults({});
  }

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    final items =
        FilterEngine.apply(widget.st.items(widget.type), widget.st, _filter);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          QuickAdd(type: widget.type, st: widget.st),
          const SizedBox(height: 12),
          Flexible(
            fit: FlexFit.loose,
            child: SingleChildScrollView(
              child: ChipsPanel(
                set: _filter,
                onUpdate: () => setState(() {}),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) {
                final it = items[i];
                final expanded = _expanded.contains(it.id);
                return ItemCard(
                  it: it,
                  st: widget.st,
                  expanded: expanded,
                  onTapTitle: () {
                    setState(() {
                      if (expanded) {
                        _expanded.remove(it.id);
                      } else {
                        _expanded.add(it.id);
                      }
                    });
                  },
                  onLongInfo: () => showInfoModal(context, it, widget.st),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
