import 'package:flutter/material.dart';
import 'package:caosbox/src/models/models.dart';  // Item, AppState, etc.
import '../utils/filter_engine.dart';            // FilterSet, FilterEngine
import 'item_card.dart';
import '../../main.dart' show Style, Behavior, showInfoModal;

class LinksBlock extends StatefulWidget {
  final AppState st;
  const LinksBlock({Key? key, required this.st}) : super(key: key);
  @override
  State<LinksBlock> createState() => _LinksBlockState();
}

class _LinksBlockState extends State<LinksBlock> with AutomaticKeepAliveClientMixin {
  final FilterSet l = FilterSet(), r = FilterSet();
  String? sel;

  @override
  void dispose() {
    l.dispose();
    r.dispose();
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
  Widget build(BuildContext context) {
    final st = widget.st;
    final leftItems = FilterEngine.apply(st.all, st, l);
    final base = st.all.where((i) => i.id != sel).toList();
    final rightItems = FilterEngine.apply(base, st, r);

    final leftList = ListView.builder(
      itemCount: leftItems.length,
      itemBuilder: (_, i) {
        final it = leftItems[i];
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
            itemCount: rightItems.length,
            itemBuilder: (_, i) {
              final it = rightItems[i];
              final checked = st.links(sel!).contains(it.id);
              return ItemCard(
                it: it,
                st: st,
                ex: false,
                onT: () {},
                onInfo: () => showInfoModal(context, it, st),
                cbR: true,
                ck: checked,
                onTapCb: () => setState(() => st.toggleLink(sel!, it.id)),
              );
            },
          );

    return Column(children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Text('Conectar elementos', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      Expanded(
        child: OrientationBuilder(
          builder: (ctx, orientation) => orientation == Orientation.portrait
              ? Column(children: [
                  Expanded(child: panel(title: 'Seleccionar:', chips: ChipsPanel(set: l, onUpdate: () => setState(() {})), body: leftList)),
                  const Divider(height: 1),
                  Expanded(child: panel(title: 'Conectar con:', chips: ChipsPanel(set: r, onUpdate: () => setState(() {})), body: rightList)),
                ])
              : Row(children: [
                  Expanded(child: panel(title: 'Seleccionar:', chips: ChipsPanel(set: l, onUpdate: () => setState(() {})), body: leftList)),
                  const VerticalDivider(width: 1),
                  Expanded(child: panel(title: 'Conectar con:', chips: ChipsPanel(set: r, onUpdate: () => setState(() {})), body: rightList)),
                ]),
        ),
      ),
    ]);
  }
}
