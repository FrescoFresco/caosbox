import 'package:flutter/material.dart';

class SimpleSearchField extends StatelessWidget {
  final String value;
  final String hint;
  final ValueChanged<String> onChanged;
  const SimpleSearchField({super.key, required this.value, required this.onChanged, this.hint = 'Buscar…'});

  @override
  Widget build(BuildContext context) {
    final ctl = TextEditingController(text: value)
      ..selection = TextSelection.collapsed(offset: value.length);
    return TextField(
      controller: ctl,
      onChanged: onChanged,
      decoration: const InputDecoration(
        hintText: 'Buscar…',
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(),
        isDense: true,
      ).copyWith(hintText: hint),
    );
  }
}
