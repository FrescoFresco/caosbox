import 'package:flutter/material.dart';
import 'package:caosbox/src/models/models.dart' as models;

class QuickAdd extends StatefulWidget {
  final models.ItemType type;
  final models.AppState st;

  const QuickAdd({
    super.key,
    required this.type,
    required this.st,
  });

  @override
  State<QuickAdd> createState() => _QuickAddState();
}

class _QuickAddState extends State<QuickAdd> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.type == models.ItemType.idea
        ? models.ideasCfg
        : models.actionsCfg;

    return Row(children: [
      Expanded(
        child: TextField(
          controller: _ctrl,
          decoration: InputDecoration(
            hintText: cfg.hint,
            prefixIcon: Icon(cfg.icon),
          ),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.send),
        onPressed: () {
          if (_ctrl.text.trim().isEmpty) return;
          widget.st.add(
            models.Item(
              id   : '${cfg.prefix}${DateTime.now().millisecondsSinceEpoch}',
              text : _ctrl.text.trim(),
              type : widget.type,
            ),
          );
          _ctrl.clear();
        },
      ),
    ]);
  }
}
