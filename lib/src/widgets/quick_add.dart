import 'package:flutter/material.dart';
import 'package:caosbox/src/models/models.dart' as models;

class QuickAdd extends StatefulWidget {
  final models.ItemType type;
  final models.AppState  st;
  final VoidCallback?    onAdded;

  const QuickAdd({
    super.key,
    required this.type,
    required this.st,
    this.onAdded,
  });

  @override
  State<QuickAdd> createState() => _QuickAddState();
}

class _QuickAddState extends State<QuickAdd> {
  final _txt = TextEditingController();

  @override
  void dispose() {
    _txt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final models.ItemTypeCfg cfg = widget.type == models.ItemType.idea
        ? models.ideasCfg
        : models.actionsCfg;

    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        leading: Icon(cfg.icon),
        title: TextField(
          controller: _txt,
          decoration: InputDecoration(
            hintText: cfg.hint,
            border: InputBorder.none,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.send),
          onPressed: () {
            final text = _txt.text.trim();
            if (text.isEmpty) return;

            final id = '${cfg.prefix}${widget.st.all.length + 1}';
            widget.st.add(models.Item(id: id, text: text, type: widget.type));
            _txt.clear();
            widget.onAdded?.call();
          },
        ),
      ),
    );
  }
}
