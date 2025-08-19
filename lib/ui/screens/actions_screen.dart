// lib/ui/screens/actions_screen.dart
import 'package:flutter/material.dart';
import '../../data/fire_repo.dart';
import '../../models/enums.dart';
import '../../models/item.dart';
import '../widgets/composer_field.dart';
import '../widgets/item_card.dart';

class ActionsScreen extends StatelessWidget {
  const ActionsScreen({super.key, required this.repo});
  final FireRepo repo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ComposerField(
          hint: 'Describe la acción…',
          onSubmit: (t) => repo.addItem(ItemType.action, t),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: StreamBuilder<List<Item>>(
            stream: repo.streamByType(ItemType.action),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = snap.data!;
              if (items.isEmpty) return const Center(child: Text('Sin acciones todavía.'));
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (c, i) {
                  final it = items[i];
                  return ItemCard(
                    item: it,
                    onStatus: (s) => repo.setStatus(it.id, s),
                    onNote: (n) => repo.setNote(it.id, n),
                    onDelete: () => repo.deleteItem(it.id),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
