import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../ui/widgets/chips_panel.dart';
import '../../ui/widgets/item_card.dart';
import '../../models/item.dart';
import '../../ui/style.dart';
import 'info_modal.dart';
import '../../models/enums.dart';

class LinksBlock extends StatefulWidget {
  final AppState state;
  const LinksBlock({super.key, required this.state});
  @override State<LinksBlock> createState() => _LinksBlockState();
}

class _LinksBlockState extends State<LinksBlock> with AutomaticKeepAliveClientMixin {
  final l = FilterSet(), r = FilterSet();
  String? sel;
  @override void dispose() { l.dispose(); r.dispose(); super.dispose(); }
  Widget pan({required String t, required Widget chips, required Widget body}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Column(children: [
      Padding(padding: const EdgeInsets.only(bottom: 8),
          child: Align(alignment: Alignment.centerLeft,
              child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)))),
      Flexible(fit: FlexFit.loose, child: SingleChildScrollView(child: chips)),
      const SizedBox(height: 8), Expanded(child: body),
    ]),
  );

  @override bool get wantKeepAlive => true;
  @override Widget build(BuildContext c) {
    super.build(c); final st = widget.state;
    final li = st.all.toList();
    final riBase = st.all.where((i) => i.id != sel).toList();
    final lf = _f(li, l, st), rf = _f(riBase, r, st);

    final lb = ListView.builder(itemCount: lf.length, itemBuilder: (_, i) {
      final it = lf[i];
      return ItemCard(item: it, st: st, ex: false,
        onT: () {}, onInfo: () => showInfoModal(c, it, st),
        trailing: Checkbox(value: sel == it.id, onChanged: (_) => setState(() => sel = sel == it.id ? null : it.id)));
    });

    final rb = sel == null
        ? const Center(child: Text('Selecciona un elemento'))
        : ListView.builder(itemCount: rf.length, itemBuilder: (_, i) {
            final it = rf[i], linked = st.links(sel!).contains(it.id);
            return ItemCard(item: it, st: st, ex: false,
              onT: () {}, onInfo: () => showInfoModal(c, it, st),
              trailing: Checkbox(value: linked, onChanged: (_) => setState(() => st.toggleLink(sel!, it.id))));
          });

    return Column(children: [
      const Padding(padding: EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Text('Conectar elementos', style: Style.title)),
      Expanded(child: OrientationBuilder(
        builder: (ctx, o) => o == Orientation.portrait
          ? Column(children: [
              Expanded(child: pan(t: 'Seleccionar:', chips: ChipsPanel(set: l, onUpdate: () => setState(() {})), body: lb)),
              const Divider(height: 1),
              Expanded(child: pan(t: 'Conectar con:', chips: ChipsPanel(set: r, onUpdate: () => setState(() {})), body: rb)),
            ])
          : Row(children: [
              Expanded(child: pan(t: 'Seleccionar:', chips: ChipsPanel(set: l, onUpdate: () => setState(() {})), body: lb)),
              const VerticalDivider(width: 1),
              Expanded(child: pan(t: 'Conectar con:', chips: ChipsPanel(set: r, onUpdate: () => setState(() {})), body: rb)),
            ]),
      )),
    ]);
  }

  List<Item> _f(List<Item> src, FilterSet set, AppState st) {
    final q = set.text.text.toLowerCase();
    return src.where((it) {
      if (q.isNotEmpty && !('${it.id} ${it.text}'.toLowerCase().contains(q))) return false;
      bool pass(FilterKey k, bool v) => switch (set.modes[k]!) {
        FilterMode.off => true, FilterMode.include => v, FilterMode.exclude => !v };
      return pass(FilterKey.completed, it.status == ItemStatus.completed) &&
             pass(FilterKey.archived,  it.status == ItemStatus.archived)  &&
             pass(FilterKey.hasLinks, st.links(it.id).isNotEmpty);
    }).toList();
  }
}
