// lib/src/widgets/chips_panel.dart
import 'package:flutter/material.dart';
import 'package:caosbox/src/utils/filter_engine.dart' as utils;

class ChipsPanel extends StatelessWidget {
  const ChipsPanel({
    super.key,
    required this.set,
    required this.onUpdate,
  });

  final utils.FilterSet set;
  final VoidCallback    onUpdate;

  @override
  Widget build(BuildContext context) {
    Widget buildChip(String label) => FilterChip(
          label    : Text(label),
          selected : false,
          onSelected: (_) => onUpdate(),
        );

    return Wrap(
      spacing: 8,
      children: [
        buildChip('✓'),
        buildChip('↓'),
        buildChip('~'),
      ],
    );
  }
}
