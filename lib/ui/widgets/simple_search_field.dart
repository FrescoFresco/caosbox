import 'package:flutter/material.dart';

class SimpleSearchField extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final EdgeInsetsGeometry? margin;
  final String? initial;

  const SimpleSearchField({
    super.key,
    this.hintText = 'Buscar…',
    required this.onChanged,
    this.margin,
    this.initial,
  });

  @override
  State<SimpleSearchField> createState() => _SimpleSearchFieldState();
}

class _SimpleSearchFieldState extends State<SimpleSearchField> {
  late final TextEditingController _c = TextEditingController(text: widget.initial ?? '');

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin ?? const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: TextField(
        controller: _c,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _c.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _c.clear();
                    widget.onChanged('');
                    setState(() {});
                  },
                  icon: const Icon(Icons.clear),
                ),
          hintText: widget.hintText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
      ),
    );
  }
}
