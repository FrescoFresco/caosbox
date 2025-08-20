import 'package:flutter/material.dart';
import '../../models/item.dart';

class AddEditSheet extends StatefulWidget {
  final ItemType type;
  final String? initialText;
  final String? initialNote;
  final List<String>? initialTags;
  final ValueChanged<(String text, String note, List<String> tags)> onSave;
  const AddEditSheet({super.key, required this.type, required this.onSave, this.initialText, this.initialNote, this.initialTags});

  @override
  State<AddEditSheet> createState() => _AddEditSheetState();
}

class _AddEditSheetState extends State<AddEditSheet> {
  late final TextEditingController _t = TextEditingController(text: widget.initialText ?? '');
  late final TextEditingController _n = TextEditingController(text: widget.initialNote ?? '');
  late final TextEditingController _g = TextEditingController(text: (widget.initialTags ?? []).join(','));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(widget.type == ItemType.b1 ? 'Añadir en B1' : 'Añadir en B2', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: ()=>Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 8),
          TextField(controller: _t, decoration: const InputDecoration(labelText: 'Título', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: _n, decoration: const InputDecoration(labelText: 'Nota', border: OutlineInputBorder()), minLines: 2, maxLines: 6),
          const SizedBox(height: 8),
          TextField(controller: _g, decoration: const InputDecoration(labelText: 'Etiquetas (coma-separadas)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final tags = _g.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                widget.onSave((_t.text.trim(), _n.text.trim(), tags));
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ),
        ],
      ),
    );
  }
}
