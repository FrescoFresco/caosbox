import 'package:flutter/material.dart';
import '../models/models.dart' as models;
import '../utils/filter_engine.dart' as engine;
import 'info_modal.dart';
import 'item_card.dart';
import 'chips_panel.dart';

class LinksBlock extends StatefulWidget {
  final models.AppState st;
  const LinksBlock({Key? key, required this.st}) : super(key: key);

  @override
  State<LinksBlock> createState() => _LinksBlockState();
}

class _LinksBlockState extends State<LinksBlock>
    with AutomaticKeepAliveClientMixin {
  final engine.FilterSet l = engine.FilterSet(), r = engine.FilterSet();
  String? sel;

  @override
  void dispose() {
    l.dispose();
    r.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  Widget panel({
    required String title,
    required Widget chips,
    required Widget body,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(title,
                  style:
                      const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          Flexible(fit: FlexFit.loose, child: SingleChildScrollView(child: chips)),
          const SizedBox(height: 8),
          Expanded(child: body),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.st;
    final left = engine.FilterEngine.apply(st.all, st, l);
    final base = st.all.where((i) => i.id != sel).toList();
    final right = engine.FilterEngine.apply(base, st, r);

    final leftList = ListView.builder(
      itemCount: left.length,
      itemBuilder: (_, i) {
        final it = left[i];
        return ItemCard(
          it: it,
          st: st,
          ex: false,
          onT: () {},
          onInfo: () => showInfoModal(context, it, st),
          cbR: true,
          ck: sel == it.id,
          onTapCb: () => setState(() => sel = sel == it.id ? null : it.id),
        );
      },
    );

    final rightList = sel == null
        ? const Center(child: Text('Selecciona un elemento'))
        : ListView.builder(
            itemCount: right.length,
            itemBuilder: (_, i) {
              final it = right[i];
              final ck = st.links(sel!).contains(it.id);
              return ItemCard(
                it: it,
                st: st,
                ex: false,
                onT: () {},
                onInfo: () => showInfoModal(context, it, st),
                cbR: true,
                ck: ck,
                onTapCb: () => setState(() => st.toggleLink(sel!, it.id)),
              );
            },
          );

    return Column(children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Text('Conectar elementos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      Expanded(
        child: OrientationBuilder(builder: (ctx, o) {
          if (o == Orientation.portrait) {
            return Column(children: [
              Expanded(
                  child: panel(
                      title: 'Seleccionar:',
                      chips: ChipsPanel(set: l, onUpdate: () => setState(() {}), defaults: const {}),
                      body: leftList)),
              const Divider(height: 1),
              Expanded(
                  child: panel(
                      title: 'Conectar con:',
                      chips: ChipsPanel(set: r, onUpdate: () => setState(() {}), defaults: const {}),
                      body: rightList)),
            ]);
          } else {
            return Row(children: [
              Expanded(
                  child: panel(
                      title: 'Seleccionar:',
                      chips: ChipsPanel(set: l, onUpdate: () => setState(() {}), defaults: const {}),
                      body: leftList)),
              const VerticalDivider(width: 1),
              Expanded(
                  child: panel(
                      title: 'Conectar con:',
                      chips: ChipsPanel(set: r, onUpdate: () => setState(() {}), defaults: const {}),
                      body: rightList)),
            ]);
          }
        }),
      ),
    ]);
  }
}
