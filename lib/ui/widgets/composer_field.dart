// lib/ui/widgets/composer_field.dart
import 'package:flutter/material.dart';

class ComposerField extends StatefulWidget {
  const ComposerField({super.key, required this.hint, required this.onSubmit});

  final String hint;
  final Future<void> Function(String text) onSubmit;

  @override
  State<ComposerField> createState() => _ComposerFieldState();
}

class _ComposerFieldState extends State<ComposerField> {
  final _c = TextEditingController();
  bool _busy = false;

  Future<void> _send() async {
    final t = _c.text.trim();
    if (t.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      await widget.onSubmit(t);
      _c.clear();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _c,
            decoration: InputDecoration(
              hintText: widget.hint,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onSubmitted: (_) => _send(),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _busy ? null : _send,
          child: _busy ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Añadir'),
        ),
      ],
    );
  }
}
