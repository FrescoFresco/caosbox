import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repo.dart';
import '../../models/item.dart';

class BlockDetail extends StatelessWidget {
  final String id;
  const BlockDetail({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<Repo>();
    return StreamBuilder<Item?>(
      stream: repo.streamItem(id),
      builder: (context, snap) {
        final it = snap.data;
        if (it == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        return DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              title: Text(it.text, maxLines: 1, overflow: TextOverflow.ellipsis),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(_statusIcon(it.status)),
                )
              ],
              bottom: const TabBar(tabs: [
                Tab(text: 'Notas'),
                Tab(text: 'Tiempo'),
                Tab(text: 'Vínculos'),
                Tab(text: 'Historial'),
              ]),
            ),
            body: TabBarView(children: [
              _NotesTab(item: it),
              _TimeTab(item: it),
              _LinksTab(item: it),
              _HistoryTab(item: it),
            ]),
          ),
        );
      },
    );
  }

  static IconData _statusIcon(ItemStatus s) {
    switch (s) {
      case ItemStatus.completed:
        return Icons.check_circle;
      case ItemStatus.archived:
        return Icons.archive;
      case ItemStatus.normal:
      default:
        return Icons.radio_button_unchecked;
    }
  }
}

class _NotesTab extends StatelessWidget {
  final Item item;
  const _NotesTab({required this.item});
  @override
  Widget build(BuildContext context) {
    final ctl = TextEditingController(text: item.note);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(controller: ctl, minLines: 4, maxLines: null, decoration: const InputDecoration(labelText: 'Notas', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                final repo = context.read<Repo>();
                await repo.updateItem(item.copyWith(note: ctl.text));
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notas guardadas')));
              },
              child: const Text('Guardar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeTab extends StatelessWidget {
  final Item item;
  const _TimeTab({required this.item});
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _DateRow(label: 'Inicio', value: item.startAt, onPick: (d) => _save(context, item.copyWith(startAt: d))),
        const SizedBox(height: 8),
        _DateRow(label: 'Vencimiento', value: item.dueAt, onPick: (d) => _save(context, item.copyWith(dueAt: d))),
      ],
    );
  }

  Future<void> _save(BuildContext context, Item it) async {
    await context.read<Repo>().updateItem(it);
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tiempo guardado')));
  }
}

class _DateRow extends StatelessWidget {
  final String label; final DateTime? value; final ValueChanged<DateTime?> onPick;
  const _DateRow({required this.label, required this.value, required this.onPick});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Text('$label: ${value == null ? '—' : value.toString().split('.').first}')),
      TextButton(
        onPressed: () async {
          final now = DateTime.now();
          final d = await showDatePicker(context: context, firstDate: DateTime(now.year - 5), lastDate: DateTime(now.year + 5), initialDate: value ?? now);
          if (!context.mounted) return;
          if (d == null) { onPick(null); return; }
          final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(value ?? now));
          if (t == null) { onPick(DateTime(d.year, d.month, d.day)); return; }
          onPick(DateTime(d.year, d.month, d.day, t.hour, t.minute));
        },
        child: const Text('Seleccionar'),
      ),
      if (value != null)
        IconButton(icon: const Icon(Icons.clear), onPressed: () => onPick(null)),
    ]);
  }
}

class _LinksTab extends StatelessWidget {
  final Item item;
  const _LinksTab({required this.item});
  @override
  Widget build(BuildContext context) {
    final repo = context.read<Repo>();
    return StreamBuilder<Set<String>>(
      stream: repo.streamLinksOf(item.id),
      builder: (context, snap) {
        final ids = snap.data ?? <String>{};
        if (ids.isEmpty) return const Center(child: Text('Sin vínculos'));
        return ListView(
          children: ids.map((id) => ListTile(
            title: StreamBuilder<Item?>(
              stream: repo.streamItem(id),
              builder: (context, s) => Text(s.data?.text ?? id, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            trailing: IconButton(icon: const Icon(Icons.link_off), onPressed: () => repo.unlink(item.id, id)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BlockDetail(id: id))),
          )).toList(),
        );
      },
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final Item item; const _HistoryTab({required this.item});
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Creado:  ${item.createdAt}'),
        const SizedBox(height: 4),
        Text('Editado: ${item.updatedAt}'),
        const SizedBox(height: 12),
        const Text('Historial simple (extiende con auditoría si quieres).'),
      ],
    );
  }
}
