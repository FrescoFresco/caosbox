// lib/ui/widgets/advanced_search.dart
import 'package:flutter/material.dart';

class SearchSpec {
  final String query; // por ahora, solo texto; luego añadimos bloques.
  const SearchSpec({this.query = ''});
}

class AdvancedSearchBar extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onSimpleQueryChanged;
  final ValueChanged<SearchSpec> onApplyAdvanced;
  final ValueChanged<String> onExportQueryJson;
  final ValueChanged<String> onImportQueryJson;

  const AdvancedSearchBar({
    super.key,
    required this.hint,
    required this.onSimpleQueryChanged,
    required this.onApplyAdvanced,
    required this.onExportQueryJson,
    required this.onImportQueryJson,
  });

  @override
  State<AdvancedSearchBar> createState() => _AdvancedSearchBarState();
}

class _AdvancedSearchBarState extends State<AdvancedSearchBar> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _c,
                onChanged: widget.onSimpleQueryChanged,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Búsqueda avanzada',
              onPressed: () => _openAdvanced(context),
              icon: const Icon(Icons.tune),
            ),
          ],
        ),
      ),
    );
  }

  void _openAdvanced(BuildContext context) {
    final adv = TextEditingController(text: _c.text);
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barra de acciones (arriba, como pediste)
            Row(
              children: [
                Text('Búsqueda avanzada', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton(onPressed: () { adv.text = ''; setState(() { _c.text = ''; }); }, child: const Text('Restablecer')),
                const SizedBox(width: 8),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    widget.onApplyAdvanced(SearchSpec(query: adv.text.trim()));
                    _c.text = adv.text.trim();
                    Navigator.pop(context);
                  },
                  child: const Text('Aplicar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // (Versión simple de bloques: de momento solo query texto)
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Texto (id, contenido, notas):', style: Theme.of(context).textTheme.labelLarge),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: adv,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.text_fields),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              minLines: 1,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            // Export / Import JSON del buscador (hooks listos)
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    // Simple: exporta solo {query:"..."} por ahora
                    final json = '{ "kind":"caosbox-query", "version":1, "query": "${adv.text.replaceAll('"', '\\"')}" }';
                    widget.onExportQueryJson(json);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Consulta exportada (JSON)')));
                  },
                  icon: const Icon(Icons.file_upload),
                  label: const Text('Exportar'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final txt = await _askText(context, 'Pegar JSON de consulta');
                    if ((txt ?? '').isEmpty) return;
                    // Simple: leemos query de una clave "query"
                    final m = RegExp(r'"query"\s*:\s*"([^"]*)"').firstMatch(txt!);
                    if (m != null) {
                      adv.text = m.group(1)!;
                      setState(() {});
                      widget.onImportQueryJson(txt);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Consulta importada')));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('JSON inválido')));
                    }
                  },
                  icon: const Icon(Icons.file_download),
                  label: const Text('Importar'),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<String?> _askText(BuildContext ctx, String title) async {
    final c = TextEditingController();
    return showDialog<String>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, autofocus: true, maxLines: 8, minLines: 4),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('OK')),
        ],
      ),
    );
  }
}
