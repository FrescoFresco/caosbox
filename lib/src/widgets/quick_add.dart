// lib/src/widgets/quick_add.dart
import 'package:flutter/material.dart';
import 'package:caosbox/src/models/models.dart' as models;

class QuickAdd extends StatefulWidget {
  const QuickAdd({
    super.key,
    required this.type,
    required this.st,
    this.onAdded,
  });

  final models.ItemType type;
  final models.AppState st;
  final VoidCallback?   onAdded;

  @override State<QuickAdd> createState() => _QuickAddState();
}

class _QuickAddState extends State<QuickAdd> {
  late final TextEditingController _c;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController();
  }

  @override
  void dispose() {
    _c.dispose();
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
          controller: _c,
          decoration: InputDecoration(
            hintText: cfg.hint,
            prefixIcon: Icon(cfg.icon),
            isDense: true,
          ),
        ),
      ),
      IconButton(
        tooltip: 'Añadir',
        icon: const Icon(Icons.add),
        onPressed: () {
          final txt = _c.text.trim();
          if (txt.isEmpty) return;
          widget.st.add(widget.type, txt);
          _c.clear();
          widget.onAdded?.call();
        },
      ),
    ]);
  }
}
