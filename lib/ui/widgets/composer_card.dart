import 'package:flutter/material.dart';
import '../style.dart';

class ComposerCard extends StatelessWidget {
  final IconData icon;
  final String hint;
  final TextEditingController c;
  final VoidCallback onAdd, onCancel;
  const ComposerCard({
    super.key,
    required this.icon,
    required this.hint,
    required this.c,
    required this.onAdd,
    required this.onCancel,
  });

  @override Widget build(BuildContext ctx) => Container(
    decoration: Style.card,
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Stack(children: [
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: TextField(
              controller: c,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(border: InputBorder.none, hintText: hint),
              minLines: 1,
              maxLines: 10,
            ),
          ),
          Positioned(left: 0, top: 0, child: Icon(icon)),
        ]),
      ),
      const Divider(height: 1),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: OverflowBar(
            alignment: MainAxisAlignment.end,
            spacing: 8,
            children: [
              TextButton(onPressed: onCancel, child: const Text('Cancelar')),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: c,
                builder: (_, v, __) => ElevatedButton(
                  onPressed: v.text.trim().isNotEmpty ? onAdd : null,
                  child: const Text('Agregar'),
                ),
              ),
            ],
          ),
        ),
      ),
    ]),
  );
}
