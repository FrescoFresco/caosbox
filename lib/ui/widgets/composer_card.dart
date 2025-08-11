import 'package:flutter/material.dart';

class ComposerCard extends StatelessWidget {
  final IconData icon;
  final String hint;
  final TextEditingController controller;
  final VoidCallback onAdd;
  final VoidCallback onCancel;

  const ComposerCard({
    super.key,
    required this.icon,
    required this.hint,
    required this.controller,
    required this.onAdd,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Stack(children: [
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                minLines: 1,
                maxLines: 8,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '',
                ),
              ),
            ),
            Positioned(left: 0, top: 0, child: Icon(icon)),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, v, __) => v.text.isEmpty
                  ? const Positioned(
                      left: 28,
                      top: 0,
                      child: Text('Escribe aquí…', style: TextStyle(color: Colors.black54)),
                    )
                  : const SizedBox.shrink(),
            ),
          ]),
        ),
        const Divider(height: 1),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: onCancel, child: const Text('Cancelar')),
              const SizedBox(width: 8),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (_, v, __) => ElevatedButton(
                  onPressed: v.text.trim().isNotEmpty ? onAdd : null,
                  child: const Text('Agregar'),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
