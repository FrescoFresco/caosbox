import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/style.dart';
import '../utils/behavior.dart';

class ItemCard extends StatelessWidget {
  const ItemCard({super.key, required this.it, required this.st, this.onEdited});
  final Item it;
  final AppState st;
  final VoidCallback? onEdited;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('${it.id}-${it.status}'),
      confirmDismiss: (dir) =>
          Behavior.swipe(dir, it.status, (s) => st.setStatus(it.id, s)),
      background: Behavior.bg(false),
      secondaryBackground: Behavior.bg(true),
      child: Container(
        decoration: Style.card,
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: Icon(Style.statusIcons[it.status]),
          title: Text(it.text),
          subtitle: Text(it.id),
          onTap: onEdited,
        ),
      ),
    );
  }
}
