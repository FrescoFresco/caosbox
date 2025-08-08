// lib/main.dart
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
import 'src/widgets/info_modal.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();          // <- usa tu firebase_options si lo prefieres
  runApp(const MyApp());
}

/* ───────────────────────────────────────────────────────────────────────── */
/*  ROOT                                                                   */
/* ───────────────────────────────────────────────────────────────────────── */

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'CaosBox',
        theme: ThemeData(useMaterial3: true),
        home: const AuthGate(),
      );
}

/* ───────────────────────────────────────────────────────────────────────── */
/*  AUTH GATE                                                               */
/* ───────────────────────────────────────────────────────────────────────── */

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
              AuthStateChangeAction((c, s) {
                if (s is SignedIn) Navigator.of(c).pushReplacement(
                  MaterialPageRoute(builder: (_) => const CaosBox()),
                );
              }),
            ],
          );
        }
        return const CaosBox();
      },
    );
  }
}

/* ───────────────────────────────────────────────────────────────────────── */
/*  MAIN APP – TABS                                                         */
/* ───────────────────────────────────────────────────────────────────────── */

class CaosBox extends StatefulWidget {
  const CaosBox({super.key});
  @override State<CaosBox> createState() => _CaosBoxState();
}

class _CaosBoxState extends State<CaosBox> {
  final _state  = AppState();
  final _filter = utils.FilterSet();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (_, __) {
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('CaosBox'),
              bottom: const TabBar(tabs: [
                Tab(icon: Icon(Icons.lightbulb), text: 'Ideas'),
                Tab(icon: Icon(Icons.assignment), text: 'Acciones'),
              ]),
            ),
            body: TabBarView(children: [
              _GenericScreen(type: ItemType.idea  , st: _state, filter: _filter),
              _GenericScreen(type: ItemType.action, st: _state, filter: _filter),
            ]),
          ),
        );
      },
    );
  }
}

/* ───────────────────────────────────────────────────────────────────────── */
/*  GENERIC LIST + COMPOSER                                                 */
/* ───────────────────────────────────────────────────────────────────────── */

class _GenericScreen extends StatefulWidget {
  const _GenericScreen({
    required this.type,
    required this.st,
    required this.filter,
  });

  final ItemType        type;
  final AppState        st;
  final utils.FilterSet filter;

  @override State<_GenericScreen> createState() => _GenericScreenState();
}

class _GenericScreenState extends State<_GenericScreen>
    with AutomaticKeepAliveClientMixin {
  late final TextEditingController _c;
  final Set<String> _expanded = <String>{};

  @override
  void initState() {
    super.initState();
    _c = TextEditingController();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final items = utils.FilterEngine.apply(
      widget.st.items(widget.type),
      widget.st,
      widget.filter,
    );

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        QuickAdd(
          type   : widget.type,
          st     : widget.st,
          onAdded: _refresh,
        ),
        const SizedBox(height: 12),
        ChipsPanel(set: widget.filter, onUpdate: _refresh),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) {
              final it   = items[i];
              final open = _expanded.contains(it.id);
              return ItemCard(
                it          : it,
                st          : widget.st,
                isExpanded  : open,
                onTapBody   : () {
                  setState(() => open
                      ? _expanded.remove(it.id)
                      : _expanded.add(it.id));
                },
                onLongInfo  : () => showInfoModal(context, it, widget.st),
              );
            },
          ),
        ),
      ]),
    );
  }
}
