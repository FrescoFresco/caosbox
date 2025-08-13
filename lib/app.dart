import 'package:flutter/material.dart';

import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/config/blocks.dart';
import 'package:caosbox/ui/screens/generic_screen.dart';
import 'package:caosbox/ui/screens/links_block.dart';

// Modelos de búsqueda (para el modal)
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
                      ? GenericScreen(block: b, st: st)  // <- usa 'st' (no 'state')
                      : LinksBlock(state: st),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ============================================================
///  FiltersSheet: Búsqueda avanzada MODULAR por BLOQUES
///  - Texto (ID/Contenido/Notas) con tokens +/- y modo (contiene/prefijo/exacto)
///  - Enum (Tipo/Estado) con Tri (include/exclude/off)
///  - Booleano (Con enlaces) con Tri
///  - Relación (Relacionado con ID) con Tri
///  Devuelve un SearchSpec con todas las cláusulas.
/// ============================================================
class FiltersSheet extends StatefulWidget {
  final SearchSpec initial;
  final AppState state;
  const FiltersSheet({super.key, required this.initial, required this.state});

  @override
  State<FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<FiltersSheet> {
  final List<Clause> _clauses = [];

  @override
  void initState() {
    super.initState();
    // Clona el spec inicial
    for (final c in widget.initial.clauses) {
      _clauses.add(c.clone());
    }
  }

  void _addBlockMenu() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('Texto (ID/Contenido/Notas)'),
            onTap: () => Navigator.pop(ctx, 'text'),
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Enum (Tipo/Estado)'),
            onTap: () => Navigator.pop(ctx, 'enum'),
          ),
          ListTile(
            leading: const Icon(Icons.toggle_on),
            title: const Text('Booleano (Con enlaces)'),
            onTap: () => Navigator.pop(ctx, 'bool'),
          ),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Relación (Relacionado con…)'),
            onTap: () => Navigator.pop(ctx, 'rel'),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (choice == null) return;
    setState(() {
      switch (choice) {
        case 'text':
          _clauses.add(TextClause(
            fields: {'id': Tri.include, 'content': Tri.include, 'note': Tri.off},
            tokens: const [],
            match: TextMatch.contains,
          ));
          break;
        case 'enum':
          _clauses.add(const EnumClause(field: 'type')); // por defecto 'type'; puedes cambiar a 'status' en el editor
          break;
        case 'bool':
          _clauses.add(const BoolClause(field: 'hasLinks', mode: Tri.include));
          break;
        case 'rel':
          _clauses.add(const RelationClause(anchorId: '', mode: Tri.include));
          break;
      }
    });
  }

  void _apply() {
    Navigator.pop(context, SearchSpec(clauses: [for (final c in _clauses) c.clone()]));
  }

  void _reset() {
    setState(() => _clauses.clear());
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      maxChildSize: 0.96,
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
                IconButton(onPressed: _addBlockMenu, icon: const Icon(Icons.add)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ]),
              const SizedBox(height: 8),
              if (_clauses.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('Añade bloques de criterios con +')),
                ),
              for (int i = 0; i < _clauses.length; i++) _buildClauseCard(i, _clauses[i]),
              const SizedBox(height: 16),
              Row(children: [
                TextButton(onPressed: _reset, child: const Text('Restablecer')),
                const Spacer(),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                const SizedBox(width: 8),
                FilledButton(onPressed: _apply, child: const Text('Aplicar')),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClauseCard(int idx, Clause c) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(_titleForClause(c), style: const TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            IconButton(
              onPressed: () => setState(() => _clauses.removeAt(idx)),
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Eliminar',
            ),
          ]),
          const SizedBox(height: 8),
          if (c is TextClause) _textClauseEditor(c, (nc) => setState(() => _clauses[idx] = nc)),
          if (c is EnumClause) _enumClauseEditor(c, (nc) => setState(() => _clauses[idx] = nc)),
          if (c is BoolClause) _boolClauseEditor(c, (nc) => setState(() => _clauses[idx] = nc)),
          if (c is RelationClause) _relClauseEditor(c, (nc) => setState(() => _clauses[idx] = nc)),
        ]),
      ),
    );
  }

  String _titleForClause(Clause c) {
    if (c is TextClause) return 'Texto';
    if (c is EnumClause) return c.field == 'type' ? 'Tipo' : 'Estado';
    if (c is BoolClause) return 'Booleano';
    if (c is RelationClause) return 'Relación';
    return 'Bloque';
  }

  // ------------------- EDITORES -------------------

  Widget _textClauseEditor(TextClause c, void Function(TextClause) onChange) {
    void setField(String k) {
      final v = c.fields[k] ?? Tri.off;
      final next = switch (v) { Tri.off => Tri.include, Tri.include => Tri.exclude, Tri.exclude => Tri.off };
      final nf = Map<String, Tri>.from(c.fields)..[k] = next;
      onChange(TextClause(fields: nf, tokens: c.tokens, match: c.match));
    }

    void addToken() async {
      final ctrl = TextEditingController();
      final mode = await showDialog<Tri>(
        context: context,
        builder: (dctx) => AlertDialog(
          title: const Text('Nuevo token'),
          content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'palabra')),
          actions: [
            TextButton(onPressed: ()=>Navigator.pop(dctx, null), child: const Text('Cancelar')),
            TextButton(onPressed: ()=>Navigator.pop(dctx, Tri.exclude), child: const Text('Añadir (-)')),
            FilledButton(onPressed: ()=>Navigator.pop(dctx, Tri.include), child: const Text('Añadir (+)')),
          ],
        ),
      );
      if (mode == null) return;
      final txt = ctrl.text.trim();
      if (txt.isEmpty) return;
      onChange(TextClause(
        fields: c.fields,
        tokens: [...c.tokens, Token(txt, mode)],
        match: c.match,
      ));
    }

    void delToken(int i) {
      final nt = [...c.tokens]..removeAt(i);
      onChange(TextClause(fields: c.fields, tokens: nt, match: c.match));
    }

    Widget chipField(String k, String label) {
      final v = c.fields[k] ?? Tri.off;
      Color? bg; String prefix = '';
      switch (v) {
        case Tri.include: bg = Colors.green.withOpacity(.15); prefix = '+'; break;
        case Tri.exclude: bg = Colors.red.withOpacity(.15);   prefix = '⊘'; break;
        case Tri.off:     bg = null;                          prefix = '';  break;
      }
      return InkWell(
        onTap: () => setField(k),
        child: Chip(label: Text('$prefix$label'), backgroundColor: bg, visualDensity: VisualDensity.compact),
      );
    }

    Widget tokenChip(Token t, int i) {
      final pref = t.mode == Tri.exclude ? '−' : '+';
      return InputChip(
        label: Text('$pref${t.t}'),
        onDeleted: () => delToken(i),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Campos', style: TextStyle(fontWeight: FontWeight.w600)),
        Wrap(spacing: 8, children: [
          chipField('id', 'ID'),
          chipField('content', 'Contenido'),
          chipField('note', 'Notas'),
        ]),
        const SizedBox(height: 8),
        const Text('Tokens', style: TextStyle(fontWeight: FontWeight.w600)),
        Wrap(spacing: 8, runSpacing: 6, children: [
          for (int i = 0; i < c.tokens.length; i++) tokenChip(c.tokens[i], i),
          ActionChip(label: const Text('Añadir token'), onPressed: addToken),
        ]),
        const SizedBox(height: 8),
        const Text('Coincidencia', style: TextStyle(fontWeight: FontWeight.w600)),
        Wrap(spacing: 8, children: [
          ChoiceChip(
            label: const Text('Contiene'),
            selected: c.match == TextMatch.contains,
            onSelected: (_) => onChange(TextClause(fields: c.fields, tokens: c.tokens, match: TextMatch.contains)),
          ),
          ChoiceChip(
            label: const Text('Prefijo'),
            selected: c.match == TextMatch.prefix,
            onSelected: (_) => onChange(TextClause(fields: c.fields, tokens: c.tokens, match: TextMatch.prefix)),
          ),
          ChoiceChip(
            label: const Text('Exacto'),
            selected: c.match == TextMatch.exact,
            onSelected: (_) => onChange(TextClause(fields: c.fields, tokens: c.tokens, match: TextMatch.exact)),
          ),
        ]),
      ],
    );
  }

  Widget _enumClauseEditor(EnumClause c, void Function(EnumClause) onChange) {
    String field = c.field;
    Set<String> include = {...c.include};
    Set<String> exclude = {...c.exclude};

    void setField(String v) {
      field = v;
      include.clear(); exclude.clear();
      onChange(EnumClause(field: field, include: include, exclude: exclude));
    }

    void toggle(String val) {
      if (include.contains(val)) { include.remove(val); exclude.add(val); }
      else if (exclude.contains(val)) { exclude.remove(val); }
      else { include.add(val); }
      onChange(EnumClause(field: field, include: include, exclude: exclude));
    }

    List<Widget> chipsForField() {
      if (field == 'status') {
        final vals = ['normal', 'completed', 'archived'];
        return vals.map((v) => _triChipVal(v, include, exclude, toggle)).toList();
      }
      // default 'type'
      final vals = ['idea', 'action'];
      return vals.map((v) => _triChipVal(v, include, exclude, toggle)).toList();
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Campo', style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Wrap(spacing: 8, children: [
        ChoiceChip(label: const Text('Tipo'), selected: field == 'type', onSelected: (_) => setField('type')),
        ChoiceChip(label: const Text('Estado'), selected: field == 'status', onSelected: (_) => setField('status')),
      ]),
      const SizedBox(height: 8),
      const Text('Valores', style: TextStyle(fontWeight: FontWeight.w600)),
      Wrap(spacing: 8, children: chipsForField()),
    ]);
  }

  Widget _boolClauseEditor(BoolClause c, void Function(BoolClause) onChange) {
    String field = c.field;
    Tri mode = c.mode;

    void setField(String v) { field = v; onChange(BoolClause(field: field, mode: mode)); }
    void setMode(Tri v) { mode = v; onChange(BoolClause(field: field, mode: mode)); }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Campo', style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Wrap(spacing: 8, children: [
        ChoiceChip(label: const Text('Con enlaces'), selected: field == 'hasLinks', onSelected: (_) => setField('hasLinks')),
      ]),
      const SizedBox(height: 8),
      const Text('Modo', style: TextStyle(fontWeight: FontWeight.w600)),
      Wrap(spacing: 8, children: [
        ChoiceChip(label: const Text('Incluir'), selected: mode == Tri.include, onSelected: (_) => setMode(Tri.include)),
        ChoiceChip(label: const Text('Excluir'), selected: mode == Tri.exclude, onSelected: (_) => setMode(Tri.exclude)),
        ChoiceChip(label: const Text('Off'),     selected: mode == Tri.off,     onSelected: (_) => setMode(Tri.off)),
      ]),
    ]);
  }

  Widget _relClauseEditor(RelationClause c, void Function(RelationClause) onChange) {
    final ctrl = TextEditingController(text: c.anchorId);
    Tri mode = c.mode;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Relacionado con (ID)', style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), hintText: 'p.ej. B1-001'),
        onChanged: (v) => onChange(RelationClause(anchorId: v.trim(), mode: mode)),
      ),
      const SizedBox(height: 8),
      const Text('Modo', style: TextStyle(fontWeight: FontWeight.w600)),
      Wrap(spacing: 8, children: [
        ChoiceChip(
          label: const Text('Incluir'),
          selected: mode == Tri.include,
          onSelected: (_) => onChange(RelationClause(anchorId: ctrl.text.trim(), mode: Tri.include)),
        ),
        ChoiceChip(
          label: const Text('Excluir'),
          selected: mode == Tri.exclude,
          onSelected: (_) => onChange(RelationClause(anchorId: ctrl.text.trim(), mode: Tri.exclude)),
        ),
      ]),
    ]);
  }

  // Helper para chips tri de EnumClause
  Widget _triChipVal(String v, Set<String> include, Set<String> exclude, void Function(String) onTap) {
    Color? bg;
    String label = v;
    if (include.contains(v)) { bg = Colors.green.withOpacity(.15); label = '+$v'; }
    else if (exclude.contains(v)) { bg = Colors.red.withOpacity(.15); label = '⊘$v'; }
    return InkWell(
      onTap: () => onTap(v),
      child: Chip(label: Text(label), backgroundColor: bg, visualDensity: VisualDensity.compact),
    );
  }
}
