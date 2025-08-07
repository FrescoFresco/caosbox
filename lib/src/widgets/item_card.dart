import 'package:flutter/material.dart';
import '../models/models.dart' as models;

class ItemCard extends StatelessWidget {
  final models.Item it;
  final models.AppState st;
  final VoidCallback? onInfo;
  const ItemCard({super.key, required this.it, required this.st, this.onInfo});

  @override Widget build(BuildContext ctx) => GestureDetector(
    onLongPress: onInfo,
    child: Container(
      decoration: models.Style.card,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(it.id, style: models.Style.id),
        const SizedBox(height:4),
        Text(it.text, style: models.Style.content),
      ]),
    ));
}
