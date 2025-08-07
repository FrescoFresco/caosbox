import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

import 'src/models/models.dart';
import 'src/utils/filter_engine.dart' as utils;
import 'src/widgets/quick_add.dart';
import 'src/widgets/chips_panel.dart';
import 'src/widgets/item_card.dart';
import 'src/widgets/links_block.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const CaosApp());
}

class CaosApp extends StatelessWidget {
  const CaosApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'CaosBox',
        theme: ThemeData(useMaterial3: true),
        home: const _AuthGate(),
      );
}

class _AuthGate extends StatelessWidget {
  const _AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return SignInScreen(
            providers: [EmailAuthProvider()],
            actions: [
              AuthStateChangeAction<SignedIn>((ctx, _) =>
                  Navigator.of(ctx).pushReplacement(
                      MaterialPageRoute(builder: (_) => const CaosBox())))
            ],
          );
        }
        return const CaosBox();
      },
    );
  }
}

/* ---------- APP SHELL ---------- */

class CaosBox extends StatefulWidget {
  const CaosBox({super.key});
  @override
  State<CaosBox> createState() => _CaosBoxState();
}

class _CaosBoxState extends State<CaosBox> {
  final _state = AppState();
  final _filter = utils.FilterSet();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (_, __) => DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('CaosBox'),
            bottom: const TabBar(tabs: [
              Tab(icon: Icon(Icons.lightbulb), text: 'Ideas'),
              Tab(icon: Icon(Icons.assignment), text: 'Acciones'),
              Tab(icon: Icon(Icons.link), text: 'Enlaces')
            ]),
          ),
          body: TabBarView(children: [
            _Board(type: ItemType.idea, st: _state, filter: _filter),
            _Board(type: ItemType.action, st: _state, filter: _filter),
            LinksBlock(st: _state)
          ]),
        ),
      ),
    );
  }
}

/* ---------- Board ---------- */

class _Board extends StatefulWidget {
  final ItemType type;
  final AppState st;
  final utils.FilterSet filter;
  const _Board({required this.type, required this.st, required this.filter});
  @override
  State<_Board> createState() => _BoardState();
}

class _BoardState extends State<_Board> with AutomaticKeepAliveClientMixin {
  final _c = TextEditingController();
  @override
  bool get wantKeepAlive => true;
  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final items = utils.FilterEngine.apply(
        widget.st.items(widget.type), widget.st, widget.filter);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        QuickAdd(type: widget.type, st: widget.st, controller: _c),
        const SizedBox(height: 12),
        ChipsPanel(set: widget.filter, onUpdate: _refresh),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) =>
                ItemCard(it: items[i], st: widget.st, onEdited: _refresh),
          ),
        )
      ]),
    );
  }
}
