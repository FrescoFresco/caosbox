// lib/ui/screens/links_screen.dart
import 'package:flutter/material.dart';
import '../../data/fire_repo.dart';
import '../../models/enums.dart';
import '../../models/item.dart';

class LinksScreen extends StatefulWidget {
  const LinksScreen({super.key, required this.repo});
  final FireRepo repo;

  @override
  State<LinksScreen> createState() => _LinksScreenState();
}

class _LinksScreenState extends State<LinksScreen> {
  String? _leftSel;
  String? _rightSel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Columna izquierda (Ideas)
        Expanded(
          child: Column(
            children: [
              const SizedBox(height: 8),
              const Text('Ideas', style: TextStyle(fontWeight: FontWeight.bold)),
              const Divider(),
              Expanded(
                child: StreamBuilder<List<Item>>(
                  stream: widget.repo.streamByType(ItemType.idea),
                  builder: (context, snap) {
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                    final items = snap.data!;
                    return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (c, i) {
                        final it = items[i];
                        final selected = _leftSel == it.id;
                        return ListTile(
                          selected: selected,
                          title: Text(it.text, maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: it.note.isNotEmpty ? Text(it.note, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                          onTap: () => setState(() => _leftSel = it.id),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Centro: botón enlazar
        Container(
          width: 120,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton(
                onPressed: (_leftSel != null && _rightSel != null && _leftSel != _rightSel)
                    ? () async {
                        await widget.repo.link(_leftSel!, _rightSel!);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enlazado')));
                        }
                      }
                    : null,
                child: const Text('Enlazar →'),
              ),
              const SizedBox(height: 16),
              Text(_leftSel == null ? 'Selecciona izq.' : 'Izq: $_leftSel', textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(_rightSel == null ? 'Selecciona der.' : 'Der: $_rightSel', textAlign: TextAlign.center),
            ],
          ),
        ),

        // Columna derecha (Acciones)
        Expanded(
          child: Column(
            children: [
              const SizedBox(height: 8),
              const Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold)),
              const Divider(),
              Expanded(
                child: StreamBuilder<List<Item>>(
                  stream: widget.repo.streamByType(ItemType.action),
                  builder: (context, snap) {
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                    final items = snap.data!;
                    return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (c, i) {
                        final it = items[i];
                        final selected = _rightSel == it.id;
                        return ListTile(
                          selected: selected,
                          title: Text(it.text, maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: it.note.isNotEmpty ? Text(it.note, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                          onTap: () => setState(() => _rightSel = it.id),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
