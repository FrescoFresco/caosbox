// lib/src/widgets/quick_add.dart

import 'package:flutter/material.dart';
import '../models/models.dart';

class QuickAdd extends StatefulWidget {
  final ItemType type;
  final AppState st;

  const QuickAdd({Key? key, required this.type, required this.st}) : super(key: key);

  @override
  State<QuickAdd> createState() => _QuickAddState();
}

class _QuickAddState extends State<QuickAdd> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final cfg = widget.type == ItemType.idea
      ? ItemTypeCfg(prefix: 'B1', icon: Icons.lightbulb, label: 'Ideas',    hint: 'Escribe tu idea…')
      : ItemTypeCfg(prefix: 'B2', icon: Icons.assignment, label: 'Acciones', hint: 'Describe la acción…');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Icon(cfg.icon),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: cfg.hint,
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          IconButton(icon: const Icon(Icons.add), onPressed: _submit),
        ]),
      ),
    );
  }

  void _submit() {
    final txt = _controller.text.trim();
    if (txt.isEmpty) return;
    widget.st.add(widget.type, txt);
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
