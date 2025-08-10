import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/enums.dart';
import '../../models/item.dart';
import '../../state/app_state.dart';
import '../widgets/item_tile.dart';

String _lbl(ItemType t) => t == ItemType.idea ? 'Idea' : 'Acción';
IconData _ico(ItemType t) => t == ItemType.idea ? Icons.lightbulb : Icons.assignment;

void showInfoModal(BuildContext c, Item it, AppState s) {
  showModalBottomSheet(context: c, isScrollControlled: true, useSafeArea: true, builder: (_) => InfoModal(id: it.id, st: s));
}

class InfoModal extends StatefulWidget {
  final String id;
  final AppState st;
  const InfoModal({super.key, required this.id, required this.st});
  @override State<InfoModal> createState() => _InfoModalState();
}

class _InfoModalState extends State<InfoModal> {
  late final TextEditingController ed;
  late final TextEditingController note;
  Timer? _deb, _debN;

  @override
  void initState() {
    super.initState();
    final cur = widget.st.getItem(widget.id)!;
    ed = TextEditingController(text: cur.text);
    note = TextEditingController(text: widget.st.note(widget.id));
  }

  @override
  void dispose() { _deb?.cancel(); _debN?.cancel(); ed.dispose(); note.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext c) {
    return AnimatedBuilder(
      animation: widget.st,
      builder: (ctx, __) {
        final cur = widget.st.getItem(widget.id)!;
        final linked = widget.st.all.where((i) => widget.st.links(widget.id).contains(i.id)).toList();
        final latestNote = widget.st.note(widget.id);
        if (note.text != latestNote) {
          note.text = latestNote;
          note.selection = TextSelection.collapsed(offset: note.text.length);
        }

        return FractionallySizedBox(
          heightFactor: 0.9,
          child: DefaultTabController(
            length: 4,
            child: Material(
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Icon(_ico(cur.type)),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${_lbl(cur.type)} • ${cur.id}', style: const TextStyle(fontWeight: FontWeight.bold))),
                    if (cur.status != ItemStatus.normal)
                      Padding(padding: const EdgeInsets.only(right: 4), child: Chip(label: Text(cur.status.name), visualDensity: VisualDensity.compact)),
                    IconButton(tooltip: 'Cerrar', icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
                  ]),
                ),
                const TabBar(tabs: [
                  Tab(icon: Icon(Icons.description), text: 'Contenido'),
                  Tab(icon: Icon(Icons.link), text: 'Relacionado'),
                  Tab(icon: Icon(Icons.info), text: 'Info'),
                  Tab(icon: Icon(Icons.timer), text: 'Tiempo'),
                ]),
                Expanded(
                  child: TabBarView(children: [
                    // Contenido
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: ed,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        minLines: 3,
                        maxLines: 10,
                        decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Escribe el contenido…'),
                        onChanged: (t) {
                          _deb?.cancel();
                          _deb = Timer(const Duration(milliseconds: 250), () => widget.st.updateText(cur.id, t));
                        },
                      ),
                    ),
                    // Relacionado (usar ItemTile + checkbox para romper/crear)
                    linked.isEmpty
                        ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.link_off, size: 48, color: Colors.grey),
                            Text('Sin relaciones', style: TextStyle(color: Colors.grey))
                          ]))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: linked.length,
                            itemBuilder: (ctx, i) {
                              final li = linked[i];
                              final ck = widget.st.links(cur.id).contains(li.id);
                              return ItemTile(
                                item: li,
                                st: widget.st,
                                expanded: false,
                                onTap: () {},
                                onInfo: () => showInfoModal(c, li, widget.st),
                                swipeable: false,
                                checkbox: true,
                                checkboxLeading: true,
                                checked: ck,
                                onChecked: (_) => widget.st.toggleLink(cur.id, li.id),
                              );
                            }),
                    // Info
                    ListView(padding: const EdgeInsets.all(16), children: [
                      _kv('📋 Tipo:', cur.type == ItemType.idea ? 'Ideas (B1)' : 'Acciones (B2)'),
                      _kv('📅 Creado:', cur.createdAt.toLocal().toString()),
                      _kv('🔄 Modificado:', cur.modifiedAt.toLocal().toString()),
                      _kv('📊 Estado:', cur.status.name),
                      _kv('🔢 Cambios:', '${cur.statusChanges}'),
                      _kv('🔗 Relaciones:', '${linked.length}'),
                    ]),
                    // Tiempo (nota)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: note,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        minLines: 3,
                        maxLines: 10,
                        decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Notas de tiempo…'),
                        onChanged: (t) {
                          _debN?.cancel();
                          _debN = Timer(const Duration(milliseconds: 250), () => widget.st.setNote(cur.id, t));
                        },
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}

Widget _kv(String k, String v) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 6),
  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    SizedBox(width: 140, child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600))),
    Expanded(child: Text(v)),
  ]),
);
