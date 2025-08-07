// lib/main.dart

import 'dart:async';
import 'package:flutter/material.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Modelos y utilidades (con alias para evitar colisiones)
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
              AuthStateChangeAction<SignedIn>((ctx, state) {
                Navigator.of(ctx).pushReplacement(
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

class CaosBox extends StatefulWidget {
  const CaosBox({super.key});
  @override State<CaosBox> createState() => _CaosBoxState();
}
class _CaosBoxState extends State<CaosBox> {
  final st = models.AppState();
  @override
  void dispose() {
    st.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext c) {
    return AnimatedBuilder(
      animation: st,
      builder: (_, __) => DefaultTabController(
        length: blocks.length,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('CaosBox'),
            bottom: TabBar(tabs: [
              for (final b in blocks) Tab(icon: Icon(b.icon), text: b.label)
            ]),
          ),
          body: SafeArea(
            child: TabBarView(children: [
              for (final b in blocks)
                if (b.type != null)
                  GenericScreen(b: b, st: st)
                else
                  b.custom!(c, st),
            ]),
          ),
        ),
      ),
    );
  }
}

// ======= Bloques y constantes =======
class ItemTypeCfg {
  final String prefix, hint, label;
  final IconData icon;
  const ItemTypeCfg({
    required this.prefix,
    required this.icon,
    required this.label,
    required this.hint,
  });
}
typedef BuilderFn = Widget Function(BuildContext, models.AppState);

class Block {
  final String id;
  final IconData icon;
  final String label;
  final models.ItemType? type;
  final ItemTypeCfg? cfg;
  final Map<models.FilterKey, models.FilterMode> defaults;
  final BuilderFn? custom;
  const Block.item({
    required this.id,
    required this.icon,
    required this.label,
    required this.type,
    required this.cfg,
    this.defaults = const {},
  }) : custom = null;
  const Block.custom({
    required this.id,
    required this.icon,
    required this.label,
    required this.custom,
  })  : type = null,
        cfg = null,
        defaults = const {};
}

final ideasCfg = ItemTypeCfg(
  prefix: 'B1',
  icon: Icons.lightbulb,
  label: 'Ideas',
  hint: 'Escribe tu idea...',
);
final actionsCfg = ItemTypeCfg(
  prefix: 'B2',
  icon: Icons.assignment,
  label: 'Acciones',
  hint: 'Describe la acción...',
);

final blocks = <Block>[
  Block.item(
    id: 'ideas',
    icon: ideasCfg.icon,
    label: ideasCfg.label,
    type: models.ItemType.idea,
    cfg: ideasCfg,
    defaults: const {models.FilterKey.completed: models.FilterMode.off},
  ),
  Block.item(
    id: 'actions',
    icon: actionsCfg.icon,
    label: actionsCfg.label,
    type: models.ItemType.action,
    cfg: actionsCfg,
    defaults: const {models.FilterKey.archived: models.FilterMode.off},
  ),
  Block.custom(
    id: 'links',
    icon: Icons.link,
    label: 'Enlaces',
    custom: (ctx, st) => LinksBlock(st: st),
  ),
];

// ======= Pantalla genérica =======
class GenericScreen extends StatefulWidget {
  final Block b;
  final models.AppState st;
  const GenericScreen({super.key, required this.b, required this.st});
  @override State<GenericScreen> createState() => _GenericScreenState();
}
class _GenericScreenState extends State<GenericScreen>
    with AutomaticKeepAliveClientMixin {
  final _filter = engine.FilterSet();
  final _expanded = <String>{};

  @override
  void initState() {
    super.initState();
    _filter.setDefaults(widget.b.defaults);
  }
  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }
  @override bool get wantKeepAlive => true;
  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext ctx) {
    super.build(ctx);
    final t = widget.b.type!;
    final cfg = widget.b.cfg!;
    final items = engine.FilterEngine.apply(
      widget.st.items(t),
      widget.st,
      _filter,
    );

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        QuickAdd(type: t, st: widget.st, cfg: cfg, onAdded: _refresh),
        const SizedBox(height: 12),
        Flexible(
          fit: FlexFit.loose,
          child: SingleChildScrollView(
            child: ChipsPanel(set: _filter, onUpdate: _refresh),
          ),
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
                isExpanded: open,
                onTap: () {
                  if (open) _expanded.remove(it.id);
                  else _expanded.add(it.id);
                  _refresh();
                },
                onLongPress: () => showInfoModal(ctx, it, widget.st),
              );
            },
          ),
        ),
      ]),
    );
  }
}
