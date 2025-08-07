// lib/src/widgets/info_modal.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/item.dart';
import '../models/app_state.dart';
import '../utils/style.dart';

void showInfoModal(BuildContext c, Item it, AppState st) {
  showModalBottomSheet(
    context: c,
    isScrollControlled: true,
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
  late TextEditingController _ed, _note;
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
  Widget build(BuildContext c) {
    final cur = widget.st.getItem(widget.id)!;
    final linked = widget.st.all.where((i) => widget.st.links(widget.id).contains(i.id)).toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: Icon(cur.type == ItemType.idea ? Icons.lightbulb : Icons.assignment),
            title: Text('${cur.id} • ${cur.text}', style: Style.title),
            trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(c).pop()),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _ed,
              maxLines: null,
              decoration: const InputDecoration(labelText: 'Contenido'),
              onChanged: (v) {
                _deb?.cancel();
                _deb = Timer(const Duration(milliseconds: 300), () => widget.st.updateText(cur.id, v));
              },
            ),
          ),
          // Aquí podrías añadir pestañas similares a tu código original…
        ]),
      ),
    );
  }
}
