import 'package:flutter/material.dart';
import 'config/blocks.dart';
import 'models/enums.dart';
import 'state/app_state.dart';
import 'ui/screens/generic_screen.dart';

class CaosApp extends StatefulWidget {
  const CaosApp({super.key});
  @override State<CaosApp> createState() => _CaosAppState();
}

class _CaosAppState extends State<CaosApp> {
  final st = AppState();
  @override void dispose() { st.dispose(); super.dispose(); }

  void _openAddSheet(BuildContext context, ItemType type) {
    final c = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16, right: 16, top: 16,
        ),
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Icon(type == ItemType.idea ? Icons.lightbulb : Icons.assignment),
              const SizedBox(width: 8),
              Text(type == ItemType.idea ? 'Nueva idea' : 'Nueva acción',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(ctx)),
            ]),
            const SizedBox(height: 8),
            TextField(
              controller: c,
              autofocus: true,
              minLines: 1, maxLines: 8,
              decoration: InputDecoration(
                hintText: type == ItemType.idea
                    ? 'Escribe tu idea...'
                    : 'Describe la acción...',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar')),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  st.add(type, c.text);
                  Navigator.pop(ctx);
                },
                child: const Text('Agregar'),
              ),
            ]),
            const SizedBox(height: 12),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CaosBox (Beta)',
      theme: ThemeData(useMaterial3: true),
      home: AnimatedBuilder(
        animation: st,
        builder: (_, __) => DefaultTabController(
          length: blocks.length,
          child: Builder(builder: (ctxWithTab) {
            final tabCtrl = DefaultTabController.of(ctxWithTab);
            return AnimatedBuilder(
              animation: tabCtrl.animation!,
              builder: (ctx, __) {
                final idx = tabCtrl.index;
                final b = blocks[idx];
                final showFab = b.type != null; // solo Ideas/Acciones
                return Scaffold(
                  appBar: AppBar(
                    title: const Text('CaosBox (Beta)'),
                    bottom: TabBar(
                      tabs: [for (final bb in blocks) Tab(icon: Icon(bb.icon), text: bb.label)],
                    ),
                  ),
                  body: SafeArea(
                    child: TabBarView(
                      children: [
                        for (final bb in blocks)
                          bb.type != null
                            ? GenericScreen(block: bb, state: st)
                            : bb.custom!(context, st),
                      ],
                    ),
                  ),
                  floatingActionButton: showFab
                      ? FloatingActionButton(
                          onPressed: () => _openAddSheet(ctx, b.type!),
                          child: const Icon(Icons.add),
                        )
                      : null,
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
