// lib/src/widgets/links_block.dart
//
// Pantalla para enlazar dos ítems entre sí (bidireccional).
// Requiere:
//   • AppState, Item, ItemType…   →  lib/src/models/models.dart
//   • FilterSet / FilterEngine    →  lib/src/utils/filter_engine.dart
//   • ChipsPanel, ItemCard, InfoModal

import 'package:flutter/material.dart';

import '../models/models.dart'           as models; // AppState, FilterSet…
import '../utils/filter_engine.dart'     as utils;  // FilterEngine
import 'chips_panel.dart';
import 'item_card.dart';
import 'info_modal.dart';

class LinksBlock extends StatefulWidget {
  final models.AppState st;
  const LinksBlock({super.key, required this.st});

  @override
  State<LinksBlock> createState() => _LinksBlockState();
}

class _LinksBlockState extends State<LinksBlock>
    with AutomaticKeepAliveClientMixin {
  // Filtros independientes para cada lista
  final lFilter = models.FilterSet();
  final rFilter = models.FilterSet();

  String? selectedId; // id elegido en la lista izquierda

  void _refresh() => setState(() {});

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final st = widget.st;

    // --------- datos filtrados ----------
    final leftItems  = utils.FilterEngine.apply(st.all, st, lFilter);

    final rightBase  = st.all.where((e) => e.id != selectedId).toList();
    final rightItems = utils.FilterEngine.apply(rightBase, st, rFilter);

    // ---------- helper visual ----------
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

    // ---------- lista izquierda ----------
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
          checked: selectedId == it.id,
          onCheckbox: () => setState(() =>
              selectedId = selectedId == it.id ? null : it.id),
        );
      },
    );

    // ---------- lista derecha ----------
    final rightList = selectedId == null
        ? const Center(child: Text('Selecciona un elemento'))
        : ListView.builder(
            itemCount: rightItems.length,
            itemBuilder: (_, i) {
              final it = rightItems[i];
              final linked = st.links(selectedId!).contains(it.id);
              return ItemCard(
                it: it,
                st: st,
                isExpanded: false,
                onTap: () {},
                onLongTap: () => showInfoModal(context, it, st),
                checkboxRight: true,
                checked: linked,
                onCheckbox: () =>
                    setState(() => st.toggleLink(selectedId!, it.id)),
              );
            },
          );

    // ---------- layout portrait / landscape ----------
    return Column(children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Text('Conectar elementos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      Expanded(
        child: OrientationBuilder(builder: (ctx, ori) {
          final portrait = ori == Orientation.portrait;
          return portrait
              ? Column(children: [
                  Expanded(
                      child: panel(
                          title: 'Seleccionar:',
                          chips: ChipsPanel(set: lFilter, onUpdate: _refresh),
                          body: leftList)),
                  const Divider(height: 1),
                  Expanded(
                      child: panel(
                          title: 'Conectar con:',
                          chips: ChipsPanel(set: rFilter, onUpdate: _refresh),
                          body: rightList)),
                ])
              : Row(children: [
                  Expanded(
                      child: panel(
                          title: 'Seleccionar:',
                          chips: ChipsPanel(set: lFilter, onUpdate: _refresh),
                          body: leftList)),
                  const VerticalDivider(width: 1),
                  Expanded(
                      child: panel(
                          title: 'Conectar con:',
                          chips: ChipsPanel(set: rFilter, onUpdate: _refresh),
                          body: rightList)),
                ]);
        }),
      ),
    ]);
  }
}
