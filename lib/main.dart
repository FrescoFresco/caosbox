import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Para evitar ambigüedades:
import 'src/models/models.dart' as models;
import 'src/utils/filter_engine.dart' as engine;

// Widgets
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
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
              })
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
  final st = models.AppState();
  @override
  Widget build(BuildContext c) {
    return AnimatedBuilder(
      animation: st,
      builder: (_, __) => DefaultTabController(
        length: blocks.length,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('CaosBox'),
            bottom: TabBar(tabs: [for (final b in blocks) Tab(icon: Icon(b.icon), text: b.label)]),
          ),
          body: SafeArea(
            child: TabBarView(children: [
              for (final b in blocks)
                if (b.type != null)
                  GenericScreen(b: b, st: st)
                else
                  b.custom!(c, st)
            ]),
          ),
        ),
      ),
    );
  }
}

class GenericScreen extends StatefulWidget {
  final Block b;
  final models.AppState st;
  const GenericScreen({super.key, required this.b, required this.st});
  @override
  State<GenericScreen> createState() => _GenericScreenState();
}

class _GenericScreenState extends State<GenericScreen> with AutomaticKeepAliveClientMixin {
  final _filter = engine.FilterSet();
  final _expanded = <String>{};

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext ctx) {
    final type = widget.b.type!;
    final items = engine.FilterEngine.apply(widget.st.items(type), widget.st, _filter);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        // QuickAdd ya sólo acepta type y st
        QuickAdd(type: type, st: widget.st),
        const SizedBox(height: 12),
        Flexible(
          fit: FlexFit.loose,
          child: SingleChildScrollView(child: ChipsPanel(set: _filter, onUpdate: _refresh, defaults: widget.b.defaults)),
        ),
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
                onInfo: () => showInfoModal(ctx, it, widget.st),
              );
            },
          ),
        ),
      ]),
    );
  }
}

// Bloques y LinksBlock, InfoModal, etc. quedan igual, sin cambios de imports aquí.
