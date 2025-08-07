// lib/src/widgets/links_block.dart
import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../utils/filter_engine.dart';
import 'chips_panel.dart';
import 'item_card.dart';
import 'info_modal.dart';

class LinksBlock extends StatefulWidget {
  final AppState st;
  const LinksBlock({super.key, required this.st});
  @override
  State<LinksBlock> createState() => _LinksBlockState();
}

class _LinksBlockState extends State<LinksBlock> with AutomaticKeepAliveClientMixin {
  final l = FilterSet(), r = FilterSet();
  String? sel;

  @override
  void dispose() {
    l.dispose();
    r.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext c) {
    super.build(c);
    final st = widget.st;
    final li = FilterEngine.apply(st.all, st, l);
    final base = st.all.where((i) => i.id != sel).toList();
    final ri = FilterEngine.apply(base, st, r);

    Widget panel(String t, FilterSet fs, Widget body) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(children: [
            Align(alignment: Alignment.centerLeft, child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(height: 8),
            ChipsPanel(set: fs, onUpdate: () => setState(() {}), defaults: const {}),
            const SizedBox(height: 8),
            Expanded(child: body),
          ]),
        );

    final lb = ListView.builder(
      itemCount: li.length,
      itemBuilder: (_, i) {
        final it = li[i];
        return ItemCard(
          it: it,
          st: st,
          onTap: () {},
          onLongInfo: () => showInfoModal(c, it, st),
        );
      },
    );
    final rb = sel == null
        ? const Center(child: Text('Selecciona un elemento'))
        : ListView.builder(
            itemCount: ri.length,
            itemBuilder: (_, i) {
              final it = ri[i];
              return ItemCard(
                it: it,
                st: st,
                onTap: () => setState(() => st.toggleLink(sel!, it.id)),
                onLongInfo: () => showInfoModal(c, it, st),
              );
            },
          );

    return Column(children: [
      const Padding(padding: EdgeInsets.all(12), child: Text('Conectar elementos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      Expanded(
        child: OrientationBuilder(builder: (ctx, o) => o == Orientation.portrait
            ? Column(children: [
                Expanded(child: panel('Seleccionar:', l, lb)),
                const Divider(height: 1),
                Expanded(child: panel('Conectar con:', r, rb)),
              ])
            : Row(children: [
                Expanded(child: panel('Seleccionar:', l, lb)),
                const VerticalDivider(width: 1),
                Expanded(child: panel('Conectar con:', r, rb)),
              ])),
      ),
    ]);
  }
}
