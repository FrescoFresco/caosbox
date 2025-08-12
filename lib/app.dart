import 'package:flutter/material.dart';

import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/config/blocks.dart';
import 'package:caosbox/ui/screens/generic_screen.dart';
import 'package:caosbox/ui/screens/links_block.dart';

// Modelos de búsqueda
import 'package:caosbox/domain/search/search_models.dart';
import 'package:caosbox/core/utils/tri.dart';

class CaosBox extends StatefulWidget {
  const CaosBox({super.key});
  @override
  State<CaosBox> createState() => _CaosBoxState();
}

class _CaosBoxState extends State<CaosBox> {
  final st = AppState();

  @override
  void dispose() {
    st.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    return AnimatedBuilder(
      animation: st,
      builder: (_, __) => DefaultTabController(
        length: blocks.length,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('CaosBox • beta'),
            bottom: TabBar(
              tabs: [for (final b in blocks) Tab(icon: Icon(b.icon), text: b.label)],
            ),
          ),
          body: SafeArea(
            child: TabBarView(
              children: [
                for (final b in blocks)
                  b.type != null
                      ? GenericScreen(block: b, st: st)   // <- CORRECTO: st: st
                      : LinksBlock(state: st),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
///  FiltersSheet: Modal de “Búsqueda avanzada” (unificado)
///  - EnumClause: type (idea/action), status (completed/archived)
///  - TextClause: campos id / content / note con Tri (off/include/exclude)
///  Devuelve un SearchSpec con las cláusulas seleccionadas.
/// ------------------------------------------------------------
class FiltersSheet extends StatefulWidget {
  final SearchSpec initial;
  final AppState state;
  const FiltersSheet({super.key, required this.initial, required this.state});

  @override
  State<FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<FiltersSheet> {
  // Estado UI (copias editables)
  // enums
  final Map<String, Tri> _type = {'idea': Tri.off, 'action': Tri.off};
  final Map<String, Tri> _status = {'completed': Tri.off, 'archived': Tri.off};
  // text fields
  final Map<String, Tri> _textFields = {'id': Tri.off, 'content': Tri.off, 'note': Tri.off};

  @override
  void initState() {
    super.initState();
    _loadFromSpec(widget.initial);
  }

  void _loadFromSpec(SearchSpec s) {
    // Resetea
    _type.updateAll((_, __) => Tri.off);
    _status.updateAll((_, __) => Tri.off);
    _textFields.updateAll((_, __) => Tri.off);

    for (final c in s.clauses) {
      if (c is EnumClause) {
        if (c.field == 'type') {
          for (final k in _type.keys) {
            if (c.include.contains(k)) _type[k] = Tri.include;
            if (c.exclude.contains(k)) _type[k] = Tri.exclude;
          }
        } else if (c.field == 'status') {
          for (final k in _status.keys) {
            if (c.include.contains(k)) _status[k] = Tri.include;
            if (c.exclude.contains(k)) _status[k] = Tri.exclude;
          }
        }
      } else if (c is TextClause) {
        for (final k in _textFields.keys) {
          _textFields[k] = c.fields[k] ?? Tri.off;
        }
      }
    }
    setState(() {});
  }

  void _cycle(Map<String, Tri> map, String key) {
    final v = map[key] ?? Tri.off;
    final next = switch (v) { Tri.off => Tri.include, Tri.include => Tri.exclude, Tri.exclude => Tri.off };
    setState(() => map[key] = next);
  }

  Widget _triChip(String label, Tri v, VoidCallback onTap) {
    Color? bg;
    IconData? ic;
    switch (v) {
      case Tri.include:
        bg = Colors.green.withOpacity(.15);
        ic = Icons.add;
        break;
      case Tri.exclude:
        bg = Colors.red.withOpacity(.15);
        ic = Icons.remove;
        break;
      case Tri.off:
        bg = null;
        ic = null;
        break;
    }
    return InkWell(
      onTap: onTap,
      child: Chip(
        label: Row(mainAxisSize: MainAxisSize.min, children: [
          if (ic != null) Padding(padding: const EdgeInsets.only(right: 4), child: Icon(ic, size: 16)),
          Text(label),
        ]),
        backgroundColor: bg,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  SearchSpec _buildSpec() {
    final clauses = <Clause>[];

    // type
    final tInc = <String>{for (final e in _type.entries) if (e.value == Tri.include) e.key};
    final tExc = <String>{for (final e in _type.entries) if (e.value == Tri.exclude) e.key};
    if (tInc.isNotEmpty || tExc.isNotEmpty) {
      clauses.add(EnumClause(field: 'type', include: tInc, exclude: tExc));
    }

    // status
    final sInc = <String>{for (final e in _status.entries) if (e.value == Tri.include) e.key};
    final sExc = <String>{for (final e in _status.entries) if (e.value == Tri.exclude) e.key};
    if (sInc.isNotEmpty || sExc.isNotEmpty) {
      clauses.add(EnumClause(field: 'status', include: sInc, exclude: sExc));
    }

    // text fields
    final hasText = _textFields.values.any((v) => v != Tri.off);
    if (hasText) {
      clauses.add(TextClause(fields: Map.of(_textFields), tokens: const []));
    }

    return SearchSpec(clauses: clauses);
  }

  void _reset() {
    _type.updateAll((_, __) => Tri.off);
    _status.updateAll((_, __) => Tri.off);
    _textFields.updateAll((_, __) => Tri.off);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, ctrl) => Material(
        child: SafeArea(
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.all(16),
            children: [
              Row(children: [
                const Text('Búsqueda avanzada', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ]),
              const SizedBox(height: 12),
              const Text('Tipo', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _triChip('Ideas', _type['idea']!, () => _cycle(_type, 'idea')),
                _triChip('Acciones', _type['action']!, () => _cycle(_type, 'action')),
              ]),
              const SizedBox(height: 16),
              const Text('Estado', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _triChip('Completado', _status['completed']!, () => _cycle(_status, 'completed')),
                _triChip('Archivado', _status['archived']!, () => _cycle(_status, 'archived')),
              ]),
              const SizedBox(height: 16),
              const Text('Campos de texto', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _triChip('ID', _textFields['id']!, () => _cycle(_textFields, 'id')),
                _triChip('Contenido', _textFields['content']!, () => _cycle(_textFields, 'content')),
                _triChip('Tiempo/Notas', _textFields['note']!, () => _cycle(_textFields, 'note')),
              ]),
              const SizedBox(height: 24),
              Row(children: [
                TextButton(onPressed: _reset, child: const Text('Restablecer')),
                const Spacer(),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => Navigator.pop(context, _buildSpec()),
                  child: const Text('Aplicar'),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
