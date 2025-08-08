import 'dart:async';
import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../models/item.dart';
import '../../utils/extensions.dart';
import '../style.dart';
import '../widgets/item_card.dart';

void showInfoModal(BuildContext ctx, Item it, AppState st) {
  showModalBottomSheet(context: ctx, isScrollControlled: true,
      builder: (_) => InfoModal(id: it.id, state: st));
}

class InfoModal extends StatefulWidget {
  final String id; final AppState state;
  const InfoModal({super.key, required this.id, required this.state});
  @override State<InfoModal> createState() => _InfoModalState();
}

class _InfoModalState extends State<InfoModal> {
  late final TextEditingController ed, note;
  Timer? _d1, _d2;
  @override void initState() {
    super.initState();
    ed   = TextEditingController(text: widget.state.getItem(widget.id)!.text);
    note = TextEditingController(text: widget.state.note(widget.id));
  }
  @override void dispose() { _d1?.cancel(); _d2?.cancel(); ed.dispose(); note.dispose(); super.dispose(); }

  @override Widget build(BuildContext ctx) => AnimatedBuilder(
    animation: widget.state,
    builder: (_, __) {
      final it = widget.state.getItem(widget.id)!, linked =
          widget.state.all.where((i) => widget.state.links(widget.id).contains(i.id)).toList();

      return FractionallySizedBox(heightFactor: .9, child: DefaultTabController(
        length: 4,
        child: Material(child: Column(children: [
          Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            const Icon(Icons.info), const SizedBox(width: 8),
            Expanded(child: Text(it.id, style: Style.title)), IconButton(
              onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
          ])),
          const TabBar(tabs: [
            Tab(icon: Icon(Icons.description), text: 'Contenido'),
            Tab(icon: Icon(Icons.link),         text: 'Relacionado'),
            Tab(icon: Icon(Icons.info),         text: 'Info'),
            Tab(icon: Icon(Icons.timer),        text: 'Tiempo'),
          ]),
          Expanded(child: TabBarView(children: [
            Padding(padding: const EdgeInsets.all(16),
              child: TextField(controller: ed, maxLines: null,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                onChanged: (t) { _d1?.cancel(); _d1 = Timer(const Duration(milliseconds: 300),
                    () => widget.state.updateText(it.id, t)); },
              )),
            linked.isEmpty
              ? const Center(child: Text('Sin relaciones'))
              : ListView.builder(
                  itemCount: linked.length,
                  itemBuilder: (_, i) => ItemCard(item: linked[i], st: widget.state, ex: false,
                      onT: () {}, onInfo: () => showInfoModal(ctx, linked[i], widget.state))),
            ListView(padding: const EdgeInsets.all(16), children: [
              _row('Creado:',     it.createdAt.f),
              _row('Modificado:', it.modifiedAt.f),
              _row('Estado:',     it.status.name),
              _row('Cambios:',    '${it.statusChanges}'),
              _row('Enlaces:',    '${linked.length}'),
            ]),
            Padding(padding: const EdgeInsets.all(16),
              child: TextField(controller: note, maxLines: null,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                onChanged: (t) { _d2?.cancel(); _d2 = Timer(const Duration(milliseconds: 300),
                    () => widget.state.setNote(it.id, t)); },
              )),
          ])),
        ])),
      ));
    });
  Widget _row(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [SizedBox(width: 120, child: Text(l, style: Style.info)), Expanded(child: Text(v))]),
  );
}
