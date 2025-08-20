import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repo.dart';
import '../../models/item.dart';
import '../../state/app_state.dart';
import '../widgets/block_tile.dart';
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
            SimpleSearchField(value: st.qB2, onChanged: st.setQB2, hint: 'Buscar en B2…'),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<Item>>(
                stream: repo.streamByType(ItemType.b2),
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final q = st.qB2.toLowerCase();
                  final items = snap.data!
                      .where((e) => e.text.toLowerCase().contains(q) || e.note.toLowerCase().contains(q) || e.tags.any((t) => t.toLowerCase().contains(q)))
                      .toList();
                  if (items.isEmpty) return const Center(child: Text('Sin elementos'));
                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (c, i) {
                      final it = items[i];
                      return BlockTile(
                        it: it,
                        onOpen: () => Navigator.push(c, MaterialPageRoute(builder: (_) => BlockDetail(id: it.id))),
                        onLong: () => showLongpressMenu(
                          c, it,
                          onOpen: () => Navigator.push(c, MaterialPageRoute(builder: (_) => BlockDetail(id: it.id))),
                          onEdit: () => _openEdit(c, it),
                          onToggleDone: () => st.toggleStatus(it),
                          onLink: () => DefaultTabController.of(c).animateTo(2),
                          onArchive: () => st.archive(it, unarchive: it.status == ItemStatus.archived),
                          onDelete: () => repo.deleteItem(it.id),
                        ),
                        onToggleStatus: () => st.toggleStatus(it),
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
        onSave: (data) async {
          await repo.addItem(ItemType.b2, text: data.$1, note: data.$2, tags: data.$3);
        },
      ),
    );
  }

  void _openEdit(BuildContext context, Item it) {
    final repo = context.read<Repo>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AddEditSheet(
        type: it.type,
        initialText: it.text,
        initialNote: it.note,
        initialTags: it.tags,
        onSave: (data) async {
          await repo.updateItem(it.copyWith(text: data.$1, note: data.$2, tags: data.$3));
        },
      ),
    );
  }
}
