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

class _LinksBlockState extends State<LinksBlock>
    with AutomaticKeepAliveClientMixin {
  final left = FilterSet(), right = FilterSet();
  String? selected;

  @override void dispose() {
    left.dispose(); right.dispose();
    super.dispose();
  }

  Widget _panel({required String title, required Widget chips, required Widget body}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          Flexible(fit: FlexFit.loose, child: SingleChildScrollView(child: chips)),
          const SizedBox(height: 8),
          Expanded(child: body),
        ]),
      );

  @override bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final st = widget.state;

    final leftItems  = st.all.toList();
    final rightItems = st.all.where((i) => i.id != selected).toList();

    final lFiltered = _applyFilter(leftItems,  left,  st);
    final rFiltered = _applyFilter(rightItems, right, st);

    final leftList = ListView.builder(
      itemCount: lFiltered.length,
      itemBuilder: (_, i) {
        final it = lFiltered[i];
        return ItemCard(
          item: it,
          st: st,
          ex: false,
          onT: () {},
          onInfo: () => showInfoModal(context, it, st),
          trailing: Checkbox(
            value: selected == it.id,
            onChanged: (_) => setState(
                () => selected = selected == it.id ? null : it.id),
          ),
        );
      },
    );

    final rightList = selected == null
        ? const Center(child: Text('Selecciona un elemento'))
        : ListView.builder(
            itemCount: rFiltered.length,
            itemBuilder: (_, i) {
              final it = rFiltered[i];
              final linked = st.links(selected!).contains(it.id);
              return ItemCard(
                item: it,
                st: st,
                ex: false,
                onT: () {},
                onInfo: () => showInfoModal(context, it, st),
                trailing: Checkbox(
                  value: linked,
                  onChanged: (_) =>
                      setState(() => st.toggleLink(selected!, it.id)),
                ),
              );
            },
          );

    return Column(children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Text('Conectar elementos', style: Style.title),
      ),
      Expanded(
        child: OrientationBuilder(
          builder: (ctx, o) => o == Orientation.portrait
              ? Column(children: [
                  Expanded(
                      child: _panel(
                          title: 'Seleccionar:',
                          chips:
                              ChipsPanel(set: left, onUpdate: () => setState(() {})),
                          body: leftList)),
                  const Divider(height: 1),
                  Expanded(
                      child: _panel(
                          title: 'Conectar con:',
                          chips:
                              ChipsPanel(set: right, onUpdate: () => setState(() {})),
                          body: rightList)),
                ])
              : Row(children: [
                  Expanded(
                      child: _panel(
                          title: 'Seleccionar:',
                          chips:
                              ChipsPanel(set: left, onUpdate: () => setState(() {})),
                          body: leftList)),
                  const VerticalDivider(width: 1),
                  Expanded(
                      child: _panel(
                          title: 'Conectar con:',
                          chips:
                              ChipsPanel(set: right, onUpdate: () => setState(() {})),
                          body: rightList)),
                ]),
        ),
      ),
    ]);
  }

  List<Item> _applyFilter(List<Item> src, FilterSet set, AppState st) {
    final q = set.text.text.toLowerCase();
    return src.where((it) {
      if (q.isNotEmpty &&
          !('${it.id} ${it.text}'.toLowerCase().contains(q))) return false;

      bool pass(FilterKey k, bool v) => switch (set.modes[k]!) {
            FilterMode.off     => true,
            FilterMode.include => v,
            FilterMode.exclude => !v,
          };

      return pass(FilterKey.completed, it.status == ItemStatus.completed) &&
          pass(FilterKey.archived,  it.status == ItemStatus.archived) &&
          pass(FilterKey.hasLinks, st.links(it.id).isNotEmpty);
    }).toList();
  }
}
