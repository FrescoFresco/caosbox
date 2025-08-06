// lib/src/widgets/quick_add.dart

import 'package:flutter/material.dart';
import '../main.dart'; // ItemType, AppState

class QuickAdd extends StatefulWidget {
  final ItemType type;
  final AppState st;
  const QuickAdd({super.key, required this.type, required this.st});
  @override
  State<QuickAdd> createState() => _QuickAddState();
}

class _QuickAddState extends State<QuickAdd> {
  final _ctrl = TextEditingController();
  void _add() {
    final txt = _ctrl.text.trim();
    if (txt.isNotEmpty) {
      widget.st.add(widget.type, txt);
      _ctrl.clear();
    }
  }
  @override
  Widget build(BuildContext context) {
    final hint = widget.type == ItemType.idea ? 'Escribe tu idea...' : 'Describe la acción...';
    final icon = widget.type == ItemType.idea ? Icons.lightbulb : Icons.assignment;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Icon(icon),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _ctrl,
              decoration: InputDecoration(hintText: hint, border: InputBorder.none, isDense: true),
              onSubmitted: (_) => _add(),
            ),
          ),
          IconButton(icon: const Icon(Icons.add), onPressed: _add),
        ]),
      ),
    );
  }
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}
