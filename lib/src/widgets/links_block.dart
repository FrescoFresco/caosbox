import 'package:flutter/material.dart';

import '../../src/models/models.dart' as models;
import '../../src/utils/filter_engine.dart' as utils;
import 'chips_panel.dart';
import 'item_card.dart';
import 'info_modal.dart';

/// Bloque para conectar dos ítems entre sí (bidireccional).
class LinksBlock extends StatefulWidget {
  final models.AppState st;
  const LinksBlock({super.key, required this.st});

  @override
  State<LinksBlock> createState() => _LinksBlockState();
}

class _LinksBlockState extends State<LinksBlock>
    with AutomaticKeepAliveClientMixin {
  final l = models.FilterSet();
  final r = models.FilterSet();
  String? sel; // id seleccionado a la izquierda

  void _refresh() => setState(() {});

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final st = widget.st;

    final leftItems  = utils.FilterEngine.apply(st.all, st, l);
    final rightBase  = st.all.where((i) => i.id != sel).toList();
    final rightItems = utils.FilterEngine.apply(rightBase, st, r);

    Widget panel({
      required String title,
      required Widget chips,
      required Widget body,
    }) =>
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 4),
            Flexible(fit: FlexFit.loose, child: SingleChildScrollView(child: chips)),
            const SizedBox(height: 8),
            Expanded(child: body),
          ]),
        );

    // Listas
    final leftList = ListView.builder(
      itemCount: leftItems.length,
      itemBuilder: (_, i) {
        final it = leftItems[i];
        return ItemCard(
          it: it,
          st: st,
          isExpanded: false,
          onTap: () {},
          onLongTap: () => showInfoModal(context, it, st),
          checkboxRight: true,
          checked: sel == it.id,
          onCheckbox: () => setState(() => sel = sel == it.id ? null : it.id),
        );
      },
    );

    final rightList = sel == null
        ? const Center(child: Text('Selecciona un elemento'))
        : ListView.builder(
            itemCount: rightItems.length,
            itemBuilder: (_, i) {
              final it = rightItems[i];
              final linked = st.links(sel!).contains(it.id);
              return ItemCard(
                it: it,
                st: st,
                isExpanded: false,
                onTap: () {},
                onLongTap: () => showInfoModal(context, it, st),
                checkboxRight: true,
                checked: linked,
                onCheckbox: () =>
                    setState(() => st.toggleLink(sel!, it.id)),
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
          final isPortrait = ori == Orientation.portrait;
          return isPortrait
              ? Column(children: [
                  Expanded(child: panel(title: 'Seleccionar:', chips: ChipsPanel(set: l, onUpdate: _refresh), body: leftList)),
                  const Divider(height: 1),
                  Expanded(child: panel(title: 'Conectar con:', chips: ChipsPanel(set: r, onUpdate: _refresh), body: rightList)),
                ])
              : Row(children: [
                  Expanded(child: panel(title: 'Seleccionar:', chips: ChipsPanel(set: l, onUpdate: _refresh), body: leftList)),
                  const VerticalDivider(width: 1),
                  Expanded(child: panel(title: 'Conectar con:', chips: ChipsPanel(set: r, onUpdate: _refresh), body: rightList)),
                ]);
        }),
      ),
    ]);
  }
}
