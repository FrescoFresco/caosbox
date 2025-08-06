// lib/src/widgets/info_modal.dart

import 'package:flutter/material.dart';
import '../models/models.dart';
import '../../main.dart'; // para AppState, showInfoModal se define aquí

void showInfoModal(BuildContext c, Item it, AppState st) {
  showModalBottomSheet(
    context: c,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => InfoModal(id: it.id, st: st),
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
  late final TextEditingController _ed;
  late final TextEditingController _note;
  Timer? _deb, _debN;

  @override
  void initState() {
    super.initState();
    _ed = TextEditingController(text: widget.st.getItem(widget.id)!.text);
    _note = TextEditingController(text: widget.st.note(widget.id));
  }

  @override
  void dispose() {
    _deb?.cancel();
    _debN?.cancel();
    _ed.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    return AnimatedBuilder(
      animation: widget.st,
      builder: (ctx, _) {
        final cur = widget.st.getItem(widget.id)!;
        final linked = widget.st
            .all
            .where((i) => widget.st.links(widget.id).contains(i.id))
            .toList();
        final latestNote = widget.st.note(widget.id);
        if (_note.text != latestNote) {
          _note.text = latestNote;
          _note.selection =
              TextSelection.collapsed(offset: latestNote.length);
        }
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: DefaultTabController(
            length: 4,
            child: Material(
              child: Column(children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Icon(cur.type == ItemType.idea
                        ? Icons.lightbulb
                        : Icons.assignment),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${cur.type.name} • ${cur.id}',
                        style:
                            const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ]),
                ),
                // Tabs
                const TabBar(tabs: [
                  Tab(icon: Icon(Icons.description), text: 'Contenido'),
                  Tab(icon: Icon(Icons.link), text: 'Relacionado'),
                  Tab(icon: Icon(Icons.info), text: 'Info'),
                  Tab(icon: Icon(Icons.timer), text: 'Tiempo'),
                ]),
                // Views
                Expanded(
                  child: TabBarView(children: [
                    // Contenido
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _ed,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Editar contenido…',
                        ),
                        minLines: 3,
                        maxLines: 10,
                        onChanged: (t) {
                          _deb?.cancel();
                          _deb = Timer(const Duration(milliseconds: 250),
                              () => widget.st.updateText(cur.id, t));
                        },
                      ),
                    ),
                    // Relacionado
                    linked.isEmpty
                        ? const Center(child: Text('Sin relaciones', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: linked.length,
                            itemBuilder: (_, i) {
                              final other = linked[i];
                              final ck = widget.st.links(widget.id).contains(other.id);
                              return CheckboxListTile(
                                title: Text(other.id),
                                value: ck,
                                onChanged: (_) =>
                                    widget.st.toggleLink(widget.id, other.id),
                              );
                            },
                          ),
                    // Info
                    ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _infoRow('Tipo', cur.type.name),
                        _infoRow('Creado', cur.createdAt.f),
                        _infoRow('Modificado', cur.modifiedAt.f),
                        _infoRow('Estado', cur.status.name),
                        _infoRow('Cambios', '${cur.statusChanges}'),
                        _infoRow('Relaciones', '${linked.length}'),
                      ],
                    ),
                    // Tiempo
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _note,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Notas…',
                        ),
                        minLines: 3,
                        maxLines: 5,
                        onChanged: (t) {
                          _debN?.cancel();
                          _debN = Timer(const Duration(milliseconds: 250),
                              () => widget.st.setNote(cur.id, t));
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

Widget _infoRow(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
        Expanded(child: Text(value)),
      ]),
    );
