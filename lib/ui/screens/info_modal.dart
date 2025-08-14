import 'dart:async';
import 'package:flutter/material.dart';
import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/core/models/item.dart';
import 'package:caosbox/core/models/enums.dart';
import 'package:caosbox/ui/widgets/search_bar.dart' as cx;

String lbl(ItemType t) => t == ItemType.idea ? 'Idea' : 'Acción';
IconData ico(ItemType t) => t == ItemType.idea ? Icons.lightbulb : Icons.assignment;

String _fmt(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}

void showInfoModal(BuildContext c, Item it, AppState s) {
  showModalBottomSheet(
    context: c,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => InfoModal(id: it.id, st: s),
  );
}

class InfoModal extends StatefulWidget {
  final String id;
  final AppState st;
  const InfoModal({super.key, required this.id, required this.st});

  @override
  State<InfoModal> createState() => _InfoModalState();
}

class _InfoModalState extends State<InfoModal> {
  late final TextEditingController _ed;     // Contenido
  late final TextEditingController _note;   // Tiempo / notas
  late final TextEditingController _qRel;   // Buscar en Relacionado
  Timer? _debT, _debN;

  @override
  void initState() {
    super.initState();
    final cur = widget.st.getItem(widget.id)!;
    _ed   = TextEditingController(text: cur.text);
    _note = TextEditingController(text: widget.st.note(widget.id));
    _qRel = TextEditingController();
  }

  @override
  void dispose() {
    _debT?.cancel(); _debN?.cancel();
    _ed.dispose(); _note.dispose(); _qRel.dispose();
    super.dispose();
  }

  bool _matchQuick(Item it) {
    final q = _qRel.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    final st = widget.st;
    final src = '${it.id} ${it.text} ${st.note(it.id)}'.toLowerCase();
    return src.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.st,
      builder: (_, __) {
        final cur = widget.st.getItem(widget.id)!;
        final linked = widget.st.links(widget.id);
        final related = widget.st.all.where((i) => i.id != cur.id).where(_matchQuick).toList();

        // sync de notas si cambian desde fuera
        final latestNote = widget.st.note(widget.id);
        if (_note.text != latestNote) {
          _note.text = latestNote;
          _note.selection = TextSelection.collapsed(offset: _note.text.length);
        }

        return FractionallySizedBox(
          heightFactor: 0.9,
          child: DefaultTabController(
            length: 4,
            child: Material(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(ico(cur.type)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${lbl(cur.type)} • ${cur.id}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (cur.status != ItemStatus.normal)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Chip(
                              label: Text(cur.status.name),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        IconButton(
                          tooltip: 'Cerrar',
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  const TabBar(
                    tabs: [
                      Tab(icon: Icon(Icons.description), text: 'Contenido'),
                      Tab(icon: Icon(Icons.link),        text: 'Relacionado'),
                      Tab(icon: Icon(Icons.info),        text: 'Info'),
                      Tab(icon: Icon(Icons.timer),       text: 'Tiempo'),
                    ],
                  ),

                  Expanded(
                    child: TabBarView(
                      children: [
                        // ===== Contenido =====
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: LayoutBuilder(
                            builder: (bCtx, cons) {
                              final base = DefaultTextStyle.of(bCtx).style;
                              final fs = base.fontSize ?? 14.0;
                              final lh = fs * (base.height ?? 1.2);
                              final hAvail = cons.maxHeight.isFinite
                                  ? cons.maxHeight
                                  : MediaQuery.of(bCtx).size.height;
                              final cap = (hAvail * 0.9).clamp(lh * 3, double.infinity);
                              final maxL = ((cap / lh).floor()).clamp(3, 2000);
                              return TextField(
                                controller: _ed,
                                keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.newline,
                                minLines: 3,
                                maxLines: maxL,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Escribe el contenido…',
                                ),
                                onChanged: (t) {
                                  _debT?.cancel();
                                  _debT = Timer(const Duration(milliseconds: 250),
                                    () => widget.st.updateText(cur.id, t),
                                  );
                                },
                              );
                            },
                          ),
                        ),

                        // ===== Relacionado =====
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16,16,16,8),
                          child: Column(
                            children: [
                              cx.SearchBar(
                                controller: _qRel,
                                onChanged: (_) => setState(() {}),
                                onOpenFilters: null, // si tienes modal avanzado, pásalo aquí
                                hint: 'Buscar relacionados…',
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: related.isEmpty
                                  ? const Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.link_off, size: 48, color: Colors.grey),
                                          SizedBox(height: 8),
                                          Text('Sin relaciones', style: TextStyle(color: Colors.grey)),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: related.length,
                                      itemBuilder: (ctx, i) {
                                        final li = related[i];
                                        final ck = linked.contains(li.id);
                                        return Card(
                                          child: ListTile(
                                            title: Text(li.text, maxLines: 1, overflow: TextOverflow.ellipsis),
                                            subtitle: Text(li.id),
                                            trailing: Checkbox(
                                              value: ck,
                                              onChanged: (_)=>setState(()=>widget.st.toggleLink(cur.id, li.id)),
                                            ),
                                            onTap: () => showInfoModal(context, li, widget.st),
                                          ),
                                        );
                                      },
                                    ),
                              ),
                            ],
                          ),
                        ),

                        // ===== Info =====
                        ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            _info('📋 Tipo:', cur.type == ItemType.idea ? 'Ideas (B1)' : 'Acciones (B2)'),
                            _info('📅 Creado:', _fmt(cur.createdAt)),
                            _info('🔄 Modificado:', _fmt(cur.modifiedAt)),
                            _info('📊 Estado:', cur.status.name),
                            _info('🔢 Cambios:', '${cur.statusChanges}'),
                            _info('🔗 Relaciones:', '${linked.length}'),
                          ],
                        ),

                        // ===== Tiempo (notas) =====
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: LayoutBuilder(
                            builder: (bCtx, cons) {
                              final base = DefaultTextStyle.of(bCtx).style;
                              final fs = base.fontSize ?? 14.0;
                              final lh = fs * (base.height ?? 1.2);
                              final hAvail = cons.maxHeight.isFinite
                                  ? cons.maxHeight
                                  : MediaQuery.of(bCtx).size.height;
                              final cap = (hAvail * 0.9).clamp(lh * 3, double.infinity);
                              final maxL = ((cap / lh).floor()).clamp(3, 2000);
                              return TextField(
                                controller: _note,
                                keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.newline,
                                minLines: 3,
                                maxLines: maxL,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Notas de tiempo…',
                                ),
                                onChanged: (t) {
                                  _debN?.cancel();
                                  _debN = Timer(const Duration(milliseconds: 250),
                                    () => widget.st.setNote(cur.id, t),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _info(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 120, child: Text(l, style: const TextStyle(fontWeight: FontWeight.w600))),
        Expanded(child: Text(v)),
      ],
    ),
  );
}
