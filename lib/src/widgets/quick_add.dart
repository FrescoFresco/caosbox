import 'package:flutter/material.dart';
import '../models/models.dart';

class QuickAdd extends StatelessWidget {
  const QuickAdd(
      {super.key, required this.type, required this.st, required this.controller});

  final ItemType type;
  final AppState st;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final icon = type == ItemType.idea ? Icons.lightbulb : Icons.assignment;
    final hint = type == ItemType.idea ? 'Nueva idea…' : 'Nueva acción…';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Icon(icon),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              decoration:
                  InputDecoration(hintText: hint, border: InputBorder.none),
              onSubmitted: (_) => _submit(),
            ),
          ),
          IconButton(icon: const Icon(Icons.add), onPressed: _submit)
        ]),
      ),
    );
  }

  void _submit() {
    final txt = controller.text.trim();
    if (txt.isEmpty) return;
    st.add(type, txt);
    controller.clear();
  }
}
