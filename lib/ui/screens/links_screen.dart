// lib/ui/screens/links_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/ui/widgets/advanced_search.dart';
import 'package:caosbox/ui/widgets/item_tile.dart';

class LinksScreen extends StatefulWidget {
  const LinksScreen({super.key});

  @override
  State<LinksScreen> createState() => _LinksScreenState();
}

class _LinksScreenState extends State<LinksScreen> {
  String _ql = '';
  String _qr = '';
  String? _selL;
  String? _selR;

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final all = st.items;

    List _filter(String q) => all.where((e) {
          if (q.trim().isEmpty) return true;
          final t = q.toLowerCase();
          return e.id.toLowerCase().contains(t) || e.text.toLowerCase().contains(t) || e.note.toLowerCase().contains(t);
        }).toList();

    final left = _filter(_ql);
    final right = _filter(_qr);

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              AdvancedSearchBar(
                hint: 'Buscar (columna izquierda)…',
                onSimpleQueryChanged: (v) => setState(() => _ql = v),
                onApplyAdvanced: (s) => setState(() => _ql = s.query),
                onExportQueryJson: (_) {},
                onImportQueryJson: (_) {},
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: left.length,
                  itemBuilder: (_, i) {
                    final it = left[i];
                    final selected = _selL == it.id;
                    return Ink(
                      color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
                      child: ItemTile(
                        compact: true,
                        item: it,
                        onTap: () => setState(() => _selL = selected ? null : it.id),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
        SizedBox(
          width: 140,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: (_selL != null && _selR != null)
                    ? () async {
                        await st.link(_selL!, _selR!);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enlace creado')));
                      }
                    : null,
                icon: const Icon(Icons.link),
                label: const Text('Enlazar'),
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: (_selL != null && _selR != null)
                    ? () async {
                        await st.unlink(_selL!, _selR!);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enlace eliminado')));
                      }
                    : null,
                icon: const Icon(Icons.link_off),
                label: const Text('Quitar'),
              ),
            ],
          ),
        ),
        VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
        Expanded(
          child: Column(
            children: [
              AdvancedSearchBar(
                hint: 'Buscar (columna derecha)…',
                onSimpleQueryChanged: (v) => setState(() => _qr = v),
                onApplyAdvanced: (s) => setState(() => _qr = s.query),
                onExportQueryJson: (_) {},
                onImportQueryJson: (_) {},
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: right.length,
                  itemBuilder: (_, i) {
                    final it = right[i];
                    final selected = _selR == it.id;
                    return Ink(
                      color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
                      child: ItemTile(
                        compact: true,
                        item: it,
                        onTap: () => setState(() => _selR = selected ? null : it.id),
                      ),
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
