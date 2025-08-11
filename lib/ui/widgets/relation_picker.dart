import 'package:flutter/material.dart';
import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/core/models/item.dart';

class RelationPicker extends StatefulWidget {
  final AppState state;
  final bool twoPane;          // true: 2 paneles (pestaña Enlaces) | false: 1 panel (InfoModal)
  final String? anchorId;      // id anclado cuando twoPane=false

  const RelationPicker({
    super.key,
    required this.state,
    this.twoPane = false,
    this.anchorId,
  });

  @override
  State<RelationPicker> createState() => _RelationPickerState();
}

class _RelationPickerState extends State<RelationPicker> with AutomaticKeepAliveClientMixin {
  final _qLeft = TextEditingController();
  final _qRight = TextEditingController();
  String? _selected; // ancla en modo twoPane

  @override
  void dispose() {
    _qLeft.dispose();
    _qRight.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  List<Item> _filter(List<Item> all, String q) {
    final s = q.trim().toLowerCase();
    if (s.isEmpty) return all;
    return all.where((i) => ('${i.id} ${i.text}'.toLowerCase().contains(s))).toList();
  }

  Widget _list(BuildContext ctx, List<Item> items, {required String? anchor, required bool checkboxOnRight}) {
    final st = widget.state;
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (_, i) {
        final it = items[i];
        if (it.id == anchor) return const SizedBox.shrink();
        final linked = anchor != null && st.links(anchor).contains(it.id);
        final cb = Checkbox(
          value: linked,
          onChanged: anchor == null ? null : (_)=> st.toggleLink(anchor, it.id),
        );
        return ListTile(
          key: ValueKey('rel_${anchor ?? "x"}_${it.id}'),
          leading: checkboxOnRight ? null : cb,
          trailing: checkboxOnRight ? cb : null,
          title: Text('${it.id} — ${it.text}', maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: anchor == null ? null : () => st.toggleLink(anchor, it.id),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final st = widget.state;

    return AnimatedBuilder(
      animation: st,
      builder: (_, __) {
        // Datos base
        final all = st.all;

        if (!widget.twoPane) {
          // MODO 1 PANEL (InfoModal): anclado a widget.anchorId, checkbox a la derecha
          final anchor = widget.anchorId!;
          final filtered = _filter(all, _qRight.text);
          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: TextField(
                controller: _qRight,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                  hintText: 'Buscar…',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState((){}),
              ),
            ),
            Expanded(child: _list(context, filtered, anchor: anchor, checkboxOnRight: true)),
          ]);
        }

        // MODO 2 PANELES (pestaña Enlaces): select izquierda → conectar derecha
        final left = _filter(all, _qLeft.text);
        final right = _filter(all.where((i) => i.id != _selected).toList(), _qRight.text);

        return OrientationBuilder(
          builder: (ctx, o) {
            final leftPanel = Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(children: [
                  const Align(alignment: Alignment.centerLeft, child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Text('Seleccionar:', style: TextStyle(fontWeight: FontWeight.bold)),
                  )),
                  TextField(
                    controller: _qLeft,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                      hintText: 'Buscar…',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_)=> setState((){}),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: left.length,
                      itemBuilder: (_, i) {
                        final it = left[i];
                        final ck = _selected == it.id;
                        return ListTile(
                          key: ValueKey('sel_${it.id}'),
                          title: Text('${it.id} — ${it.text}', maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: Checkbox(value: ck, onChanged: (_)=> setState(()=> _selected = ck ? null : it.id)),
                          onTap: ()=> setState(()=> _selected = ck ? null : it.id),
                        );
                      },
                    ),
                  ),
                ]),
              ),
            );

            final rightPanel = Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(children: [
                  const Align(alignment: Alignment.centerLeft, child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Text('Conectar con:', style: TextStyle(fontWeight: FontWeight.bold)),
                  )),
                  TextField(
                    controller: _qRight,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                      hintText: 'Buscar…',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_)=> setState((){}),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _selected == null
                        ? const Center(child: Text('Selecciona un elemento a la izquierda'))
                        : _list(context, right, anchor: _selected, checkboxOnRight: false), // ⟵ checkbox a la IZQ
                  ),
                ]),
              ),
            );

            return o == Orientation.portrait
                ? Column(children: [leftPanel, const Divider(height: 1), rightPanel])
                : Row(children: [leftPanel, const VerticalDivider(width: 1), rightPanel]);
          },
        );
      },
    );
  }
}
