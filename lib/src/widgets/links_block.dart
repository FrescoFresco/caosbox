// lib/src/widgets/links_block.dart

import 'package:flutter/material.dart';
import '../main.dart'; // AppState, ItemType, Item
import 'chips_panel.dart';
import 'item_card.dart';
import '../src/filters.dart';

class LinksBlock extends StatefulWidget {
  final AppState st;
  const LinksBlock({super.key, required this.st});
  @override
  State<LinksBlock> createState() => _LinksBlockState();
}

class _LinksBlockState extends State<LinksBlock> with AutomaticKeepAliveClientMixin {
  final leftFilter = FilterSet(), rightFilter = FilterSet();
  String? selectedId;

  @override void dispose() {
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
          child: Align(alignment: Alignment.centerLeft, child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
        ),
        Flexible(fit: FlexFit.loose, child: SingleChildScrollView(child: chips)),
        const SizedBox(height: 8),
        Expanded(child: body),
      ]),
    );
  }

  @override bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final st = widget.st;
    final allItems = st.all.where((i) => i.id != selectedId).toList();
    final leftList = FilterEngine.apply(st.all, st, leftFilter);
    final rightList = selectedId == null
        ? const Center(child: Text('Selecciona un elemento'))
        : ListView.builder(
            itemCount: FilterEngine.apply(allItems, st, rightFilter).length,
            itemBuilder: (_, i) {
              final it = FilterEngine.apply(allItems, st, rightFilter)[i];
              final ck = st.links(selectedId!).contains(it.id);
              return ItemCard(
                it: it,
                st: st,
                expanded: false,
                onTapTitle: () {},
                onLongInfo: () => showInfoModal(context, it, st),
                cbRight: true,
                checked: ck,
                onToggleLink: () => setState(() => st.toggleLink(selectedId!, it.id)),
              );
            },
          );

    return Column(children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Text('Conectar elementos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      Expanded(
        child: OrientationBuilder(builder: (ctx, ori) {
          if (ori == Orientation.portrait) {
            return Column(children: [
              Expanded(child: panel(
                title: 'Seleccionar:',
                chips: ChipsPanel(set: leftFilter, onUpdate: () => setState(() {})),
                body: ListView.builder(
                  itemCount: leftList.length,
                  itemBuilder: (_, i) {
                    final it = leftList[i];
                    final sel = selectedId == it.id;
                    return ItemCard(
                      it: it,
                      st: st,
                      expanded: false,
                      onTapTitle: () => setState(() => selectedId = sel ? null : it.id),
                      onLongInfo: () => showInfoModal(context, it, st),
                      cbRight: true,
                      checked: sel,
                      onToggleLink: () => setState(() => selectedId = sel ? null : it.id),
                    );
                  },
                ),
              )),
              const Divider(height: 1),
              Expanded(child: panel(
                title: 'Conectar con:',
                chips: ChipsPanel(set: rightFilter, onUpdate: () => setState(() {})),
                body: rightList,
              )),
            ]);
          } else {
            return Row(children: [
              Expanded(child: panel(
                title: 'Seleccionar:',
                chips: ChipsPanel(set: leftFilter, onUpdate: () => setState(() {})),
                body: ListView.builder(
                  itemCount: leftList.length,
                  itemBuilder: (_, i) {
                    final it = leftList[i];
                    final sel = selectedId == it.id;
                    return ItemCard(
                      it: it,
                      st: st,
                      expanded: false,
                      onTapTitle: () => setState(() => selectedId = sel ? null : it.id),
                      onLongInfo: () => showInfoModal(context, it, st),
                      cbRight: true,
                      checked: sel,
                      onToggleLink: () => setState(() => selectedId = sel ? null : it.id),
                    );
                  },
                ),
              )),
              const VerticalDivider(width: 1),
              Expanded(child: panel(
                title: 'Conectar con:',
                chips: ChipsPanel(set: rightFilter, onUpdate: () => setState(() {})),
                body: rightList,
              )),
            ]);
          }
        }),
      ),
    ]);
  }
}
