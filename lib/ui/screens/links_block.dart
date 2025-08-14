import 'package:flutter/material.dart';

import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/core/models/item.dart';
import 'package:caosbox/ui/screens/info_modal.dart';
import 'package:caosbox/ui/widgets/search_bar.dart' as cx; // <— buscador modular
import 'package:caosbox/ui/widgets/item_card.dart';
import 'package:caosbox/ui/widgets/chips_panel.dart';

class LinksBlock extends StatefulWidget {
  final AppState st;
  const LinksBlock({super.key, required this.st});

  @override
  State<LinksBlock> createState() => _LinksBlockState();
}

class _LinksBlockState extends State<LinksBlock>
    with AutomaticKeepAliveClientMixin {
  final _l = FilterSet();
  final _r = FilterSet();

  final _qL = TextEditingController(); // quick search izquierda
  final _qR = TextEditingController(); // quick search derecha

  String? sel; // id seleccionado en la columna izquierda

  @override
  void dispose() {
    _l.dispose();
    _r.dispose();
    _qL.dispose();
    _qR.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  bool _matchQuickL(Item it) {
    final q = _qL.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    final src =
        '${it.id} ${it.text} ${widget.st.note(it.id)}'.toLowerCase();
    return src.contains(q);
  }

  bool _matchQuickR(Item it) {
    final q = _qR.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    final src =
        '${it.id} ${it.text} ${widget.st.note(it.id)}'.toLowerCase();
    return src.contains(q);
  }

  Widget _panel({
    required String title,
    required Widget searchRow,
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
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // buscador modular de cada columna
          searchRow,
          const SizedBox(height: 8),
          Expanded(child: body),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext c) {
    super.build(c);
    final st = widget.st;

    // Fuente de datos
    final all = st.all;

    // Columna izquierda: elegir base
    final li = FilterEngine.apply(
      all.where(_matchQuickL).toList(),
      st,
      _l,
    );

    // Columna derecha: candidatos (excluye el seleccionado)
    final baseRight = all.where((i) => i.id != sel).toList();
    final ri = FilterEngine.apply(
      baseRight.where(_matchQuickR).toList(),
      st,
      _r,
    );

    // cuerpo lista izquierda
    final lb = ListView.builder(
      itemCount: li.length,
      itemBuilder: (_, i) {
        final it = li[i];
        final ck = sel == it.id;
        return ItemCard(
          it: it,
          st: st,
          ex: false,
          onT: () {}, // sin expandir aquí
          onInfo: () => showInfoModal(c, it, st),
          // checkbox a la DERECHA en la columna izquierda (como acordamos)
          cbR: true,
          ck: ck,
          onTapCb: () => setState(() => sel = ck ? null : it.id),
        );
      },
    );

    // cuerpo lista derecha
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
                onInfo: () => showInfoModal(c, it, st),
                // checkbox a la IZQUIERDA en la columna derecha (como acordamos)
                cbL: true,
                ck: ck,
                onTapCb: () => setState(() => st.toggleLink(sel!, it.id)),
              );
            },
          );

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Text('Conectar elementos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: OrientationBuilder(
            builder: (ctx, o) => o == Orientation.portrait
                ? Column(
                    children: [
                      Expanded(
                        child: _panel(
                          title: 'Seleccionar:',
                          searchRow: cx.SearchBar(
                            controller: _qL,
                            onChanged: (_) => setState(() {}),
                            onOpenFilters: () {
                              // filtros avanzados izquierda
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                builder: (_) => Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ChipsPanel(
                                        set: _l,
                                        onUpdate: () => setState(() {}),
                                        defaults: const {},
                                      ),
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: ElevatedButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Aplicar'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            hint: 'Buscar…',
                          ),
                          body: lb,
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: _panel(
                          title: 'Conectar con:',
                          searchRow: cx.SearchBar(
                            controller: _qR,
                            onChanged: (_) => setState(() {}),
                            onOpenFilters: () {
                              // filtros avanzados derecha
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                builder: (_) => Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ChipsPanel(
                                        set: _r,
                                        onUpdate: () => setState(() {}),
                                        defaults: const {},
                                      ),
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: ElevatedButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Aplicar'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            hint: 'Buscar…',
                          ),
                          body: rb,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _panel(
                          title: 'Seleccionar:',
                          searchRow: cx.SearchBar(
                            controller: _qL,
                            onChanged: (_) => setState(() {}),
                            onOpenFilters: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                builder: (_) => Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ChipsPanel(
                                        set: _l,
                                        onUpdate: () => setState(() {}),
                                        defaults: const {},
                                      ),
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: ElevatedButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Aplicar'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            hint: 'Buscar…',
                          ),
                          body: lb,
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: _panel(
                          title: 'Conectar con:',
                          searchRow: cx.SearchBar(
                            controller: _qR,
                            onChanged: (_) => setState(() {}),
                            onOpenFilters: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                builder: (_) => Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ChipsPanel(
                                        set: _r,
                                        onUpdate: () => setState(() {}),
                                        defaults: const {},
                                      ),
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: ElevatedButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Aplicar'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            hint: 'Buscar…',
                          ),
                          body: rb,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
