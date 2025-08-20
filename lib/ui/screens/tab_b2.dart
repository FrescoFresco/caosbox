import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repo.dart';
import '../../models/item.dart';
import '../../state/app_state.dart';

import '../widgets/block_card.dart';
import '../widgets/simple_search_field.dart';
import '../widgets/add_edit_sheet.dart';
import '../widgets/longpress_menu.dart';

import 'block_detail.dart';

class TabB2 extends StatelessWidget {
  const TabB2({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<Repo>();
    final st = context.watch<AppState>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            SimpleSearchField(
              value: st.qB2,
              onChanged: st.setQB2,
              hint: 'Buscar en B2…',
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<Item>>(
                stream: repo.streamByType(ItemType.b2),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final q = st.qB2.toLowerCase();
                  final items = snap.data!
                      .where((e) =>
                          e.text.toLowerCase().contains(q) ||
                          e.note.toLowerCase().contains(q))
                      .toList();

                  if (items.isEmpty) {
                    return const Center(child: Text('Sin elementos'));
                  }

                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (c, i) {
                      final it = items[i];
                      return BlockCard(
                        it: it,
                        onTap: () => Navigator.push(
                          c,
                          MaterialPageRoute(
                            builder: (_) => BlockDetail(id: it.id),
                          ),
                        ),
                        onLongPress: () => showLongpressMenu(
                          c,
                          it,
                          onOpen: () => Navigator.push(
                            c,
                            MaterialPageRoute(
                              builder: (_) => BlockDetail(id: it.id),
                            ),
                          ),
                          onEdit: () => _openEdit(c, it),
                          onToggleDone: () => st.toggleStatus(it),
                          onLink: () => DefaultTabController.of(c).animateTo(2),
                          onArchive: () =>
                              st.archive(it, unarchive: it.status == ItemStatus.archived),
                          onDelete: () => repo.deleteItem(it.id),
                        ),
                        onToggleStatus: () => st.toggleStatus(it),
                        // linkCount: opcional si llevas la cuenta de vínculos
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAdd(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openAdd(BuildContext context) {
    final repo = context.read<Repo>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AddEditSheet(
        type: ItemType.b2,
        onSave: (d) async {
          await repo.addItem(
            ItemType.b2,
            text: d.$1,
            note: d.$2,
            tags: d.$3,
          );
        },
      ),
    );
  }

  void _openEdit(BuildContext context, I_
