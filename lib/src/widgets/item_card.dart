// lib/src/widgets/item_card.dart
import 'package:flutter/material.dart';
import 'package:caosbox/src/models/models.dart';

class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    required this.it,
    required this.st,
    this.onTapBody,
    this.onLongInfo,
    this.isExpanded = false,
  });

  final Item       it;
  final AppState   st;
  final VoidCallback? onTapBody;
  final VoidCallback? onLongInfo;
  final bool          isExpanded;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap      : onTapBody,
        onLongPress: onLongInfo,
        leading    : Icon(it.type == ItemType.idea ? Icons.lightbulb : Icons.assignment),
        title      : Text(it.text, maxLines: isExpanded ? null : 1),
        subtitle   : Text(it.id),
      ),
    );
  }
}
