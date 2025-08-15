import 'package:flutter/material.dart';

import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/config/blocks.dart';
import 'package:caosbox/ui/screens/generic_screen.dart';

/// App raíz
class CaosApp extends StatelessWidget {
  const CaosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CaosBox • beta',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const CaosHome(),
    );
  }
}

/// Home con tabs (Ideas, Acciones, Enlaces…)
class CaosHome extends StatefulWidget {
  const CaosHome({super.key});

  @override
  State<CaosHome> createState() => _CaosHomeState();
}

class _CaosHomeState extends State<CaosHome> {
  final AppState st = AppState();

  @override
  void dispose() {
    st.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: st,
      builder: (_, __) {
        return DefaultTabController(
          length: blocks.length,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('CaosBox • beta'),
              bottom: TabBar(
                tabs: [
                  for (final b in blocks) Tab(icon: Icon(b.icon), text: b.label),
                ],
              ),
            ),
            body: SafeArea(
              child: TabBarView(
                children: [
                  for (final b in blocks)
                    // Si es un bloque de items (B1/B2), usamos GenericScreen.
                    // Si es custom (Enlaces), delegamos al builder definido en blocks.dart.
                    b.type != null
                        ? GenericScreen(block: b, st: st)
                        : b.custom!(context, st),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
