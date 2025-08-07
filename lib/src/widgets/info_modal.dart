import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';  // Para formatear fechas

import '../models/item.dart';
import '../models/app_state.dart';

class InfoModal extends StatefulWidget {
  final String id;
  final AppState st;
  const InfoModal({Key? key, required this.id, required this.st}) : super(key: key);

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
    final cur = widget.st.getItem(widget.id)!;
    _ed = TextEditingController(text: cur.text);
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
  Widget build(BuildContext context) {
    final cur = widget.st.getItem(widget.id)!;
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

    return FractionallySizedBox(
      heightFactor: 0.9,
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: Text('Detalle • ${cur.id}'),
          ),
          body: Column(
            children: [
              TabBar(tabs: const [
                Tab(text: 'Contenido'),
                Tab(text: 'Relacionado'),
                Tab(text: 'Info'),
                Tab(text: 'Notas'),
              ]),
              Expanded(
                child: TabBarView(children: [
                  // Contenido
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _ed,
                      maxLines: null,
                      onChanged: (t) {
                        _deb?.cancel();
                        _deb = Timer(const Duration(milliseconds: 250), () {
                          widget.st.updateText(cur.id, t);
                        });
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  // Relacionado
                  Center(child: Text('Aquí irían los ítems relacionados')),
                  // Info
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _infoRow('Tipo', cur.type.name),
                        _infoRow('Creado', fmt.format(cur.createdAt)),
                        _infoRow('Modificado', fmt.format(cur.modifiedAt)),
                        _infoRow('Estado', cur.status.name),
                        _infoRow('Cambios', '${cur.statusChanges}'),
                        _infoRow('Relaciones', '${widget.st.links(cur.id).length}'),
                      ],
                    ),
                  ),
                  // Notas
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _note,
                      maxLines: null,
                      onChanged: (t) {
                        _debN?.cancel();
                        _debN = Timer(const Duration(milliseconds: 250), () {
                          widget.st.setNote(cur.id, t);
                        });
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Escribe tus notas aquí…',
                      ),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
