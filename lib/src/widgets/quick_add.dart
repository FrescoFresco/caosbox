import 'package:flutter/material.dart';
import '../../src/models/models.dart' as models; // importa ItemTypeCfg y demás
import '../../src/models/models.dart' show ItemType; // para ItemType
import '../../src/app_state.dart'; // si AppState está en otro fichero, corrige la ruta
// Si AppState está en models.dart, usa:
// import '../../src/models/models.dart' show AppState;

class QuickAdd extends StatefulWidget {
  final ItemType type;
  final models.AppState st;

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
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.st.add(widget.type, text);
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
