import 'package:flutter/material.dart';
import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/config/blocks.dart';
import 'package:caosbox/ui/screens/generic_screen.dart';

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

class CaosHome extends StatefulWidget {
  const CaosHome({super.key});
  @override
  State<CaosHome> createState() => _CaosHomeState();
}

class _CaosHomeState extends State<CaosHome> {
  final AppState st = AppState();

  @override
  void dispose() { st.dispose(); super.dispose(); }

  void _openAddSheet(BuildContext context, Block b) {
    final t = b.type!; final cfg = b.cfg!;
    final txt = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true, useSafeArea: true,
      builder: (_) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: Icon(cfg.icon),
              title: TextField(
                controller: txt,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                minLines: 1, maxLines: 6,
                decoration: InputDecoration(
                  hintText: cfg.hint,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Cancelar')),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final v = txt.text.trim();
                  if (v.isNotEmpty) { st.add(t, v); }
                  Navigator.pop(context);
                },
                child: const Text('Agregar'),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: st,
      builder: (_, __) {
        return DefaultTabController(
          length: blocks.length,
          child: Builder(builder: (ctxDT) {
            final tc = DefaultTabController.of(ctxDT)!;
            return AnimatedBuilder(
              animation: tc,
              builder: (_, __) {
                final b = blocks[tc.index];
                final showFab = b.type != null;
                return Scaffold(
                  appBar: AppBar(
                    title: const Text('CaosBox • beta'),
                    bottom: TabBar(tabs: [
                      for (final x in blocks) Tab(icon: Icon(x.icon), text: x.label)
                    ]),
                  ),
                  body: SafeArea(
                    child: TabBarView(
                      children: [
                        for (final x in blocks)
                          x.type != null ? GenericScreen(block: x, st: st) : x.custom!(context, st),
                      ],
                    ),
                  ),
                  floatingActionButton: showFab
                      ? FloatingActionButton.extended(
                          icon: Icon(b.cfg!.icon),
                          label: const Text('Añadir'),
                          onPressed: () => _openAddSheet(context, b),
                        )
                      : null,
                );
              },
            );
          }),
        );
      },
    );
  }
}
