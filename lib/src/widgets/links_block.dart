// lib/src/widgets/links_block.dart

import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/filter_engine.dart';
import 'chips_panel.dart';
import 'item_card.dart';
import 'info_modal.dart';

class LinksBlock extends StatefulWidget {
  final AppState st;
  const LinksBlock({Key? key, required this.st}) : super(key: key);

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

  Widget panel({required String t, required Widget chips, required Widget body}) =>
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Align(alignment: Alignment.centerLeft, child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold))),
        ),
        Flexible(fit: FlexFit.loose, child: SingleChildScrollView(child: chips)),
        const SizedBox(height: 8),
        Expanded(child: body),
      ]),
    );

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext c) {
    super.build(c);
    final st   = widget.st;
    final li   = FilterEngine.apply(st.all, st, l);
    final base = st.all.where((i) => i.id != sel).toList();
    final ri   = FilterEngine.apply(base, st, r);

    final lb = ListView.builder(
      itemCount: li.length,
      itemBuilder: (_, i) {
        final it = li[i];
        return ItemCard(
          it: it,
          st: st,
          ex: false,
          onT: () {},
          onLongInfo: () => showInfoModal(c, it, st),
          cbR: true,
          ck: sel == it.id,
          onTapCb: () => setState(() => sel = sel == it.id ? null : it.id),
        );
      },
    );

    final rb = sel == null
      ? const Center(child: Text('Selecciona un elemento'))
      : ListView.builder(
          itemCount: ri.length,
          itemBuilder: (_, i) {
            final it = ri[i];
            final ck = st.links(sel!).contains(it.id);
            return ItemCard(
              it: it,
              st: st,
              ex: false,
              onT: () {},
              onLongInfo: () => showInfoModal(c, it, st),
              cbR: true,
              ck: ck,
              onTapCb: () => setState(() => st.toggleLink(sel!, it.id)),
            );
          },
        );

    return Column(children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Text('Conectar elementos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      Expanded(
        child: OrientationBuilder(builder: (ctx, o) => o == Orientation.portrait
          ? Column(children: [
              Expanded(child: panel(t: 'Seleccionar:', chips: ChipsPanel(set: l, onUpdate: () => setState(() {})), body: lb)),
              const Divider(height: 1),
              Expanded(child: panel(t: 'Conectar con:', chips: ChipsPanel(set: r, onUpdate: () => setState(() {})), body: rb)),
            ])
          : Row(children: [
              Expanded(child: panel(t: 'Seleccionar:', chips: ChipsPanel(set: l, onUpdate: () => setState(() {})), body: lb)),
              const VerticalDivider(width: 1),
              Expanded(child: panel(t: 'Conectar con:', chips: ChipsPanel(set: r, onUpdate: () => setState(() {})), body: rb)),
            ])),
      ),
    ]);
  }
}
