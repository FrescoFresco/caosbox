import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../models/item.dart';
import '../widgets/item_tile.dart';
import 'info_modal.dart';

class LinksBlock extends StatefulWidget {
  final AppState st;
  const LinksBlock({super.key, required this.st});
  @override State<LinksBlock> createState() => _LinksBlockState();
}

class _LinksBlockState extends State<LinksBlock> with AutomaticKeepAliveClientMixin {
  String? sel;
  @override bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext c) {
    super.build(c);
    final st = widget.st;
    final all = st.all;

    Widget listLeft(List<Item> src) => ListView.builder(
      itemCount: src.length,
      itemBuilder: (_, i) {
        final it = src[i];
        final ck = sel == it.id;
        return ItemTile(
          item: it,
          st: st,
          expanded: false,
          onTap: () => setState(() => sel = ck ? null : it.id),
          onInfo: () => showInfoModal(c, it, st),
          swipeable: false,
          checkbox: true,
          checkboxLeading: true,
          checked: ck,
          onChecked: (_) => setState(() => sel = ck ? null : it.id),
        );
      },
    );

    Widget listRight(List<Item> src) => ListView.builder(
      itemCount: src.length,
      itemBuilder: (_, i) {
        final it = src[i];
        final ck = sel != null && st.links(sel!).contains(it.id);
        return ItemTile(
          item: it,
          st: st,
          expanded: false,
          onTap: () {},
          onInfo: () => showInfoModal(c, it, st),
          swipeable: false,
          checkbox: true,
          checkboxLeading: false,
          checked: ck,
          onChecked: (_) => setState(() { if (sel != null) st.toggleLink(sel!, it.id); }),
        );
      },
    );

    final rightData = sel == null ? <Item>[] : all.where((x) => x.id != sel).toList();

    return Column(children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Text('Conectar elementos', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      Expanded(
        child: Row(children: [
          Expanded(child: Column(children: [
            const Padding(
              padding: EdgeInsets.only(left: 12, bottom: 8),
              child: Align(alignment: Alignment.centerLeft, child: Text('Seleccionar:')),
            ),
            Expanded(child: listLeft(all)),
          ])),
          const VerticalDivider(width: 1),
          Expanded(child: Column(children: [
            const Padding(
              padding: EdgeInsets.only(left: 12, bottom: 8),
              child: Align(alignment: Alignment.centerLeft, child: Text('Conectar con:')),
            ),
            Expanded(
              child: sel == null
                ? const Center(child: Text('Selecciona un elemento'))
                : listRight(rightData),
            ),
          ])),
        ]),
      ),
    ]);
  }
}
