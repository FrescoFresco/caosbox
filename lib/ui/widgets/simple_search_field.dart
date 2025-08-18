import 'package:flutter/material.dart';

class SimpleSearchField extends StatelessWidget {
  final String hint;
  final String value;
  final ValueChanged<String> onChanged;

  const SimpleSearchField({
    super.key,
    this.hint = 'Buscar…',
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: value)
        ..selection = TextSelection.collapsed(offset: value.length),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
