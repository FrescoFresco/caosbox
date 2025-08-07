import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

// modelos & utilidades
import 'src/models/models.dart'  as models;
import 'src/utils/filter_engine.dart' as utils;
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
  Widget build(BuildContext context) => MaterialApp(
        title: 'CaosBox',
        theme: ThemeData(useMaterial3: true),
        home: const AuthGate(),
      );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (!snap.hasData) {
            return SignInScreen(
              providers: [EmailAuthProvider()],
              actions: [
                AuthStateChangeAction((ctx, state) {
                  if (state is SignedIn) {
                    Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_) => const CaosBox()));
                  }
                })
              ],
            );
          }
          return const CaosBox();
        },
      );
}

class CaosBox extends StatefulWidget {
  const CaosBox({super.key});
  @override
  State<CaosBox> createState() => _CaosBoxState();
}

class _CaosBoxState extends State<CaosBox> {
  final _state = models.AppState();
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
              Tab(text: 'Ideas', icon: Icon(Icons.lightbulb)),
              Tab(text: 'Acciones', icon: Icon(Icons.assignment)),
              Tab(text: 'Enlaces', icon: Icon(Icons.link)),
            ]),
          ),
          body: TabBarView(children: [
            _buildGeneric(models.ItemType.idea),
            _buildGeneric(models.ItemType.action),
            LinksBlock(st: _state),
          ]),
        ),
      ),
    );
  }

  Widget _buildGeneric(models.ItemType type) {
    final items = utils.FilterEngine.apply(_state.items(type), _state, _filter);
    final cfg   = type == models.ItemType.idea ? models.ideasCfg : models.actionsCfg;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        QuickAdd(type: type, st: _state),
        const SizedBox(height: 12),
        ChipsPanel(set: _filter, onUpdate: () => setState(() {})),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) => ItemCard(
              it: items[i],
              st: _state,
              onInfo: () => showInfoModal(context, items[i], _state),
            ),
          ),
        ),
      ]),
    );
  }
}
