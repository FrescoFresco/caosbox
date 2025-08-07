import 'package:flutter/material.dart';
import '../models/models.dart' as models;

class QuickAdd extends StatefulWidget {
  final models.ItemType type;
  final models.AppState st;
  const QuickAdd({super.key, required this.type, required this.st});

  @override State<QuickAdd> createState() => _QuickAddState();
}

class _QuickAddState extends State<QuickAdd> {
  final _c = TextEditingController();
  @override void dispose() { _c.dispose(); super.dispose(); }

  @override Widget build(BuildContext ctx) {
    final cfg = widget.type == models.ItemType.idea ? models.ideasCfg : models.actionsCfg;
    return Row(children: [
      Expanded(child: TextField(controller: _c, decoration: InputDecoration(hintText: cfg.hint))),
      IconButton(icon: Icon(cfg.icon), onPressed: _add),
    ]);
  }
  void _add() {
    if (_c.text.trim().isEmpty) return;
    widget.st.add(widget.type, _c.text.trim());
    _c.clear();
  }
}
