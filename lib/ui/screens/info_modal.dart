import 'dart:async';
import 'package:flutter/material.dart';
import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/core/models/item.dart';
import 'package:caosbox/core/models/enums.dart';
import 'package:caosbox/ui/theme/style.dart';

import 'package:caosbox/ui/widgets/content_block.dart';
import 'package:caosbox/domain/search/search_models.dart';

String lbl(ItemType t) => t == ItemType.idea ? 'Idea' : 'Acción';
IconData ico(ItemType t) => t == ItemType.idea ? Icons.lightbulb : Icons.assignment;

void showInfoModal(BuildContext c, Item it, AppState s) {
  showModalBottomSheet(context: c, isScrollControlled: true, useSafeArea: true, builder: (_) => InfoModal(id: it.id, st: s));
}

class InfoModal extends StatefulWidget{
  final String id; final AppState st;
  const InfoModal({super.key, required this.id, required this.st});
  @override State<InfoModal> createState()=>_InfoModalState();
}

class _InfoModalState extends State<InfoModal>{
  late final TextEditingController ed;
  late final TextEditingController note;
  Timer? _deb,_debN;

  @override void initState(){
    super.initState();
    ed   = TextEditingController(text: widget.st.getItem(widget.id)!.text);
    note = TextEditingController(text: widget.st.note(widget.id));
  }
  @override void dispose(){ _deb?.cancel(); _debN?.cancel(); ed.dispose(); note.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext c){
    return AnimatedBuilder(animation: widget.st, builder: (ctx, __) {
      final cur = widget.st.getItem(widget.id)!;
      final latestNote = widget.st.note(widget.id);
      if (note.text != latestNote) { note.text = latestNote; note.selection = TextSelection.collapsed(offset: note.text.length); }

      return FractionallySizedBox(
        heightFactor: 0.9,
        child: DefaultTabController(
          length: 3,
          child: Material(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Icon(ico(cur.type)), const SizedBox(width: 8),
                  Expanded(child: Text('${lbl(cur.type)} • ${cur.id}', style: Style.title, overflow: TextOverflow.ellipsis)),
                  IconButton(tooltip: 'Cerrar', icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
                ]),
              ),
              const TabBar(tabs: [
                Tab(icon: Icon(Icons.description), text: 'Contenido'),
                Tab(icon: Icon(Icons.link),        text: 'Relacionado'),
                Tab(icon: Icon(Icons.timer),       text: 'Tiempo'),
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
                    onChanged: (t) { _deb?.cancel(); _deb = Timer(const Duration(milliseconds: 250), ()=>widget.st.updateText(cur.id, t)); },
                  ),
                ),
                // Relacionado (mismo bloque, 1 panel, check a la derecha)
                ContentBlock(
                  state: widget.st,
                  types: null,
                  spec: const SearchSpec(),
                  quickQuery: '',
                  onQuickQuery: (_){},
                  onOpenFilters: (){},      // oculto
                  showComposer: false,
                  mode: ContentBlockMode.link,
                  anchorId: cur.id,
                  checkboxSide: CheckboxSide.right,
                ),
                // Tiempo
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: note,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    minLines: 3, maxLines: 12,
                    decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Notas de tiempo…'),
                    onChanged: (t) { _debN?.cancel(); _debN = Timer(const Duration(milliseconds: 250), ()=>widget.st.setNote(cur.id, t)); },
                  ),
                ),
              ])),
            ]),
          ),
        ),
      );
    });
  }
}
