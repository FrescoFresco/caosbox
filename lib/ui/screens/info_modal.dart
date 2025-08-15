import 'dart:async';
import 'package:flutter/material.dart';
import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/core/models/enums.dart';
import 'package:caosbox/core/models/item.dart';
import 'package:caosbox/ui/widgets/item_card.dart';
import 'package:caosbox/ui/widgets/search_bar.dart' as cx;

String lbl(ItemType t)=> t==ItemType.idea? 'Idea':'Acción';
IconData ico(ItemType t)=> t==ItemType.idea? Icons.lightbulb: Icons.assignment;

void showInfoModal(BuildContext c, Item it, AppState s) {
  showModalBottomSheet(context: c, isScrollControlled: true, useSafeArea: true, builder: (_) => InfoModal(id: it.id, st: s));
}

class InfoModal extends StatefulWidget {
  final String id; final AppState st;
  const InfoModal({super.key, required this.id, required this.st});
  @override State<InfoModal> createState()=>_InfoModalState();
}

class _InfoModalState extends State<InfoModal> {
  late final TextEditingController ed;
  late final TextEditingController note;
  late final TextEditingController relQ;
  Timer? _deb, _debN;

  @override void initState() {
    super.initState();
    ed = TextEditingController(text: widget.st.getItem(widget.id)!.text);
    note = TextEditingController(text: widget.st.note(widget.id));
    relQ = TextEditingController();
  }

  @override void dispose() {
    _deb?.cancel(); _debN?.cancel();
    ed.dispose(); note.dispose(); relQ.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    return AnimatedBuilder(
      animation: widget.st,
      builder: (ctx, __) {
        final cur = widget.st.getItem(widget.id)!;
        final latestNote = widget.st.note(widget.id);
        if (note.text != latestNote) {
          note.text = latestNote;
          note.selection = TextSelection.collapsed(offset: note.text.length);
        }
        final linkedIds = widget.st.links(widget.id);
        final relatedAll = widget.st.all.where((x) => x.id != widget.id).toList();

        List<Item> related = relatedAll.where((it){
          final q = relQ.text.trim().toLowerCase(); if (q.isEmpty) return true;
          return ('${it.id} ${it.text} ${widget.st.note(it.id)}'.toLowerCase()).contains(q);
        }).toList();

        return FractionallySizedBox(
          heightFactor: 0.92,
          child: DefaultTabController(
            length: 4,
            child: Material(
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children:[
                    Icon(ico(cur.type)),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${lbl(cur.type)} • ${cur.id}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                    if (cur.status != ItemStatus.normal)
                      Padding(padding: const EdgeInsets.only(right: 4),
                        child: Chip(label: Text(cur.status.name), visualDensity: VisualDensity.compact)),
                    IconButton(tooltip: 'Cerrar', icon: const Icon(Icons.close), onPressed: ()=>Navigator.of(ctx).pop()),
                  ]),
                ),
                const TabBar(tabs: [
                  Tab(icon: Icon(Icons.description), text: 'Contenido'),
                  Tab(icon: Icon(Icons.link), text: 'Relacionado'),
                  Tab(icon: Icon(Icons.info), text: 'Info'),
                  Tab(icon: Icon(Icons.timer), text: 'Tiempo'),
                ]),
                Expanded(child: TabBarView(children: [
                  // Contenido
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: ed,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      minLines: 3, maxLines: 12,
                      decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Escribe el contenido…'),
                      onChanged: (t){
                        _deb?.cancel();
                        _deb = Timer(const Duration(milliseconds: 250), () => widget.st.updateText(cur.id, t));
                      },
                    ),
                  ),
                  // Relacionado (misma UI de buscador + tiles)
                  Column(children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: cx.SearchBar(controller: relQ, onChanged: (_)=>setState((){}), onOpenFilters: null, hint: 'Buscar relacionados…'),
                    ),
                    Expanded(child: related.isEmpty
                      ? const Center(child: Text('Sin resultados'))
                      : ListView.builder(
                          itemCount: related.length,
                          itemBuilder: (_, i) {
                            final it = related[i];
                            final ck = linkedIds.contains(it.id);
                            return ItemCard(
                              it: it, st: widget.st, ex: false,
                              onT: (){}, onInfo: ()=>showInfoModal(c, it, widget.st),
                              cbR: true, ck: ck, onTapCb: ()=> widget.st.toggleLink(cur.id, it.id),
                            );
                          },
                        ),
                    ),
                  ]),
                  // Info
                  ListView(padding: const EdgeInsets.all(16), children: [
                    _info('📋 Tipo:', cur.type == ItemType.idea ? 'Ideas (B1)' : 'Acciones (B2)'),
                    _info('📅 Creado:', cur.createdAt.toIso8601String()),
                    _info('🔄 Modificado:', cur.modifiedAt.toIso8601String()),
                    _info('📊 Estado:', cur.status.name),
                    _info('🔢 Cambios:', '${cur.statusChanges}'),
                    _info('🔗 Relaciones:', '${linkedIds.length}'),
                  ]),
                  // Tiempo (nota libre)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: note,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      minLines: 3, maxLines: 12,
                      decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Notas de tiempo…'),
                      onChanged: (t){
                        _debN?.cancel();
                        _debN = Timer(const Duration(milliseconds: 250), ()=> widget.st.setNote(cur.id, t));
                      },
                    ),
                  ),
                ])),
              ]),
            ),
          ),
        );
      },
    );
  }
}

Widget _info(String l, String v) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 6),
  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    SizedBox(width: 120, child: Text(l, style: const TextStyle(fontWeight: FontWeight.w600))),
    Expanded(child: Text(v)),
  ]),
);
