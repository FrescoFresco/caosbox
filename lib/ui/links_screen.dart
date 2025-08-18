// lib/ui/links_screen.dart
import 'package:flutter/material.dart';
import '../data/fire_repo.dart';
import '../models.dart';

class LinksScreen extends StatefulWidget {
  final FireRepo repo;
  const LinksScreen({super.key, required this.repo});

  @override
  State<LinksScreen> createState() => _LinksScreenState();
}

class _LinksScreenState extends State<LinksScreen> {
  late final _items$ = widget.repo.watchItemsAll();
  final _qa = TextEditingController();
  final _qb = TextEditingController();
  String? _selA;
  String? _selB;

  @override
  void dispose() {
    _qa.dispose();
    _qb.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _items$,
      builder: (context, snap) {
        final all = (snap.data ?? const <dynamic>[]) as List;
        final qA = _qa.text.trim().toLowerCase();
        final qB = _qb.text.trim().toLowerCase();

        List<dynamic> filter(List<dynamic> xs, String q) {
          if (q.isEmpty) return xs;
          return xs.where((it) {
            final s = '${it.idHuman} ${it.text} ${it.note}'.toLowerCase();
            return s.contains(q);
          }).toList();
        }

        final left  = filter(all, qA);
        final right = filter(all, qB);

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _searchBox(_qa, 'Buscar A…')),
                  const SizedBox(width: 8),
                  Expanded(child: _searchBox(_qb, 'Buscar B…')),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: (_selA != null && _selB != null && _selA != _selB)
                        ? () async {
                            await widget.repo.toggleLink(_selA!, _selB!);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Conexión A↔B actualizada')),
                              );
                            }
                          }
                        : null,
                    icon: const Icon(Icons.link),
                    label: const Text('Conectar A↔B'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _listColumn('Columna A', left, (id) {
                      setState(() => _selA = id == _selA ? null : id);
                    }, _selA)),
                    const SizedBox(width: 12),
                    Expanded(child: _listColumn('Columna B', right, (id) {
                      setState(() => _selB = id == _selB ? null : id);
                    }, _selB)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (_selA != null) _linksChips(title: 'Enlaces de ${_selA!}', id: _selA!),
              if (_selB != null) _linksChips(title: 'Enlaces de ${_selB!}', id: _selB!),
            ],
          ),
        );
      },
    );
  }

  Widget _searchBox(TextEditingController c, String hint) {
    return TextField(
      controller: c,
      decoration: InputDecoration(
        hintText: hint,
        border: const OutlineInputBorder(),
        isDense: true,
        suffixIcon: c.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  c.clear();
                  setState(() {});
                },
              ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _listColumn(String title, List<dynamic> xs, void Function(String) onTap, String? selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemBuilder: (c, i) {
              final it = xs[i];
              final sel = selected == it.idHuman;
              return Card(
                color: sel ? Colors.blueGrey.shade50 : null,
                child: ListTile(
                  title: Text('${it.idHuman}  ${it.text}'),
                  subtitle: it.note.isEmpty ? null : Text(it.note),
                  onTap: () => onTap(it.idHuman),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: xs.length,
          ),
        ),
      ],
    );
  }

  Widget _linksChips({required String title, required String id}) {
    return StreamBuilder<Set<String>>(
      stream: widget.repo.watchLinksFor(id),
      builder: (context, snap) {
        final set = snap.data ?? const <String>{};
        if (set.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 6,
              runSpacing: -8,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0, bottom: 4),
                  child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                for (final x in set) Chip(label: Text(x)),
              ],
            ),
          ),
        );
      },
    );
  }
}
