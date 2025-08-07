import 'package:flutter/material.dart';
import '../models/models.dart';     // AppState, Item, FilterSet, FilterEngine
import 'chips_panel.dart';
import 'item_card.dart';
import 'info_modal.dart';           // showInfoModal

class LinksBlock extends StatefulWidget {
  final AppState st;
  const LinksBlock({super.key, required this.st});

  @override
  State<LinksBlock> createState() => _LinksBlockState();
}

class _LinksBlockState extends State<LinksBlock> with AutomaticKeepAliveClientMixin {
  final FilterSet leftFilter = FilterSet();
  final FilterSet rightFilter = FilterSet();
  String? selected;

  @override
  void dispose() {
    leftFilter.dispose();
    rightFilter.dispose();
    super.dispose();
  }

  Widget panel({required String title, required Widget chips, required Widget body}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        Flexible(fit: FlexFit.loose, child: SingleChildScrollView(child: chips)),
        const SizedBox(height: 8),
        Expanded(child: body),
      ]),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext c) {
    super.build(c);
    final st = widget.st;

    final leftItems = FilterEngine.apply(st.all, st, leftFilter);
    final other = st.all.where((i) => i.id != selected).toList();
    final rightItems = FilterEngine.apply(other, st, rightFilter);

    final leftList = ListView.builder(
      itemCount: leftItems.length,
      itemBuilder: (_, i) {
        final it = leftItems[i];
        return ItemCard(
          it: it,
          st: st,
          ex: false,
          onT: () {},
          onInfo: () => showInfoModal(c, it, st),
          cbR: true,
          ck: selected == it.id,
          onTapCb: () => setState(() => selected = (selected == it.id ? null : it.id)),
        );
      },
    );

    final rightList = selected == null
        ? const Center(child: Text('Selecciona un elemento'))
        : ListView.builder(
            itemCount: rightItems.length,
            itemBuilder: (_, i) {
              final it = rightItems[i];
              final linked = st.links(selected!);
              final ck = linked.contains(it.id);
              return ItemCard(
                it: it,
                st: st,
                ex: false,
                onT: () {},
                onInfo: () => showInfoModal(c, it, st),
                cbR: true,
                ck: ck,
                onTapCb: () => setState(() => st.toggleLink(selected!, it.id)),
              );
            },
          );

    return Column(children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Text('Conectar elementos', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      Expanded(
        child: OrientationBuilder(builder: (ctx, o) {
          if (o == Orientation.portrait) {
            return Column(children: [
              Expanded(child: panel(title: 'Seleccionar:', chips: ChipsPanel(set: leftFilter, onUpdate: () => setState(() {})), body: leftList)),
              const Divider(height: 1),
              Expanded(child: panel(title: 'Conectar con:', chips: ChipsPanel(set: rightFilter, onUpdate: () => setState(() {})), body: rightList)),
            ]);
          } else {
            return Row(children: [
              Expanded(child: panel(title: 'Seleccionar:', chips: ChipsPanel(set: leftFilter, onUpdate: () => setState(() {})), body: leftList)),
              const VerticalDivider(width: 1),
              Expanded(child: panel(title: 'Conectar con:', chips: ChipsPanel(set: rightFilter, onUpdate: () => setState(() {})), body: rightList)),
            ]);
          }
        }),
      ),
    ]);
  }
}
