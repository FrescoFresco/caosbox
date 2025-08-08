import 'package:flutter/material.dart';
import 'config/blocks.dart';
import 'state/app_state.dart';
import 'ui/screens/generic_screen.dart';

class CaosApp extends StatefulWidget {
  const CaosApp({super.key});
  @override State<CaosApp> createState() => _CaosAppState();
}

class _CaosAppState extends State<CaosApp> {
  final _state = AppState();
  @override void dispose() { _state.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CaosBox',
      theme: ThemeData(useMaterial3: true),
      home: AnimatedBuilder(
        animation: _state,
        builder: (_, __) => DefaultTabController(
          length: blocks.length,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('CaosBox'),
              bottom: TabBar(
                tabs: [for (final b in blocks) Tab(icon: Icon(b.icon), text: b.label)],
              ),
            ),
            body: SafeArea(
              child: TabBarView(
                children: [
                  for (final b in blocks)
                    b.type != null
                        ? GenericScreen(block: b, state: _state)
                        : b.custom!(context, _state),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
