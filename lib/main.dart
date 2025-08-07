import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'src/models/app_state.dart';
import 'src/models/item.dart';
import 'src/utils/filter_engine.dart';
import 'src/utils/style.dart';
import 'src/utils/behavior.dart';
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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
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
              AuthStateChangeAction<SignedIn>((ctx, state) {
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
          body: SafeArea(
            child: TabBarView(children: [
              // Ideas
              GenericScreen(type: ItemType.idea, st: st),
              // Acciones
              GenericScreen(type: ItemType.action, st: st),
              // Enlaces
              LinksBlock(st: st),
            ]),
          ),
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
    _filter.setDefaults(const {});
  }

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final items = FilterEngine.apply(
      widget.st.items(widget.type),
      widget.st,
      _filter,
    );
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        QuickAdd(type: widget.type, st: widget.st, onAdded: _refresh),
        const SizedBox(height: 12),
        ChipsPanel(set: _filter, onUpdate: _refresh),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) {
              final it = items[i];
              final open = _expanded.contains(it.id);
              return ItemCard(
                it: it,
                st: widget.st,
                ex: open,
                onT: () {
                  setState(() {
                    if (open) _expanded.remove(it.id);
                    else _expanded.add(it.id);
                  });
                },
                onInfo: () => showInfoModal(context, it, widget.st),
              );
            },
          ),
        ),
      ]),
    );
  }
}
