// lib/src/widgets/quick_add.dart
import 'package:flutter/material.dart';
import '../models/item.dart';
import '../models/app_state.dart';

class QuickAdd extends StatefulWidget {
  final ItemType type;
  final AppState st;
  const QuickAdd({super.key, required this.type, required this.st});

  @override
  State<QuickAdd> createState() => _QuickAddState();
}

class _QuickAddState extends State<QuickAdd> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final cfg = widget.type == ItemType.idea ? ideasCfg : actionsCfg;
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
    if (txt.isNotEmpty) {
      widget.st.add(widget.type, txt);
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
