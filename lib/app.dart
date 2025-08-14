import 'package:flutter/material.dart';

import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/config/blocks.dart';
import 'package:caosbox/ui/screens/generic_screen.dart';
import 'package:caosbox/ui/screens/links_block.dart';

import 'package:caosbox/domain/search/search_models.dart';
import 'package:caosbox/domain/search/search_engine.dart';
import 'package:caosbox/search/search_io.dart';
import 'package:caosbox/core/utils/tri.dart';

class CaosBox extends StatefulWidget {
  const CaosBox({super.key});
  @override
  State<CaosBox> createState() => _CaosBoxState();
}

class _CaosBoxState extends State<CaosBox> {
  final st = AppState();

  @override
  void dispose() { st.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext c) {
    return AnimatedBuilder(
      animation: st,
      builder: (_, __) => DefaultTabController(
        length: blocks.length,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('CaosBox • beta'),
            bottom: TabBar(tabs: [for (final b in blocks) Tab(icon: Icon(b.icon), text: b.label)]),
          ),
          body: SafeArea(
            child: TabBarView(children: [
              for (final b in blocks)
                b.type != null ? GenericScreen(block: b, st: st)
                               : LinksBlock(state: st),
            ]),
          ),
        ),
      ),
    );
  }
}

/// ============================================================
///  FiltersSheet (MVP): 2 tipos de bloque (text/flag) + conectores AND/OR
///  Botones arriba: +, Import, Export, ↺, OK, ✕
/// ============================================================
class FiltersSheet extends StatefulWidget {
  final SearchSpec initial;
  final AppState state;
  const FiltersSheet({super.key, required this.initial, required this.state});

  @override
  State<FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<FiltersSheet> {
  // Representación lineal con conector antes de cada bloque (excepto primero)
  final _items = <_Entry>[]; // _Entry(opBefore, clause)

  @override
  void initState() {
    super.initState();
    _fromTree(widget.initial.root);
  }

  // ----- serialización lineal <-> árbol (fold left) -----

  void _fromTree(GroupNode root) {
    _items.clear();
    // aplanar: AND/OR binario a secuencia con conectores
    void dfs(QueryNode node, {Op? incoming}) {
      if (node is LeafNode) {
        _items.add(_Entry(op: incoming, clause: node.clause.clone()));
        return;
      }
      if (node is GroupNode && node.children.isNotEmpty) {
        // fold left: (((c0 op c1) op c2) ...)
        QueryNode acc = node.children.first;
        for (int i = 1; i < node.children.length; i++) {
          final op = node.op;
          final nxt = node.children[i];
          // cuando acc es primera hoja, emite acc sin op; las siguientes con op
          if (i == 1) dfs(acc, incoming: incoming); // preserva op externo
          dfs(nxt, incoming: op);
          acc = GroupNode(op: op, children: [acc, nxt]); // solo para avanzar
        }
      }
    }
    dfs(root);
    if (_items.isEmpty) {
      // inicia con un bloque de texto simple
      _items.add(_Entry(op: null, clause: const TextClause(element: 'content')));
    }
    setState(() {});
  }

  GroupNode _toTree() {
    // pliega la lista lineal en árbol binario: (((c0 op c1) op c2) ...)
    if (_items.isEmpty) {
      return const GroupNode(op: Op.and, children: []);
    }
    // primer bloque sin op -> base
    QueryNode acc = LeafNode(clause: _items.first.clause.clone());
    for (int i = 1; i < _items.length; i++) {
      final e = _items[i];
      final op = e.op ?? Op.and;
      final leaf = LeafNode(clause: e.clause.clone());
      acc = GroupNode(op: op, children: [acc, leaf]);
    }
    // si todo fue OR/AND homogéneo, devuelve un group; si no, igualmente encadenado
    if (acc is GroupNode) return acc;
    return GroupNode(op: Op.and, children: [acc]);
  }

  // ----- acciones -----

  void _addBlock() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.text_fields), title: const Text('Texto'), onTap: () => Navigator.pop(ctx, 'text')),
          ListTile(leading: const Icon(Icons.flag),        title: const Text('Bandera'), onTap: () => Navigator.pop(ctx, 'flag')),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (choice == null) return;
    setState(() {
      if (choice == 'text') {
        _items.add(_Entry(op: Op.and, clause: const TextClause(element: 'content')));
      } else {
        _items.add(_Entry(op: Op.and, clause: const FlagClause(field: 'hasLinks', mode: Tri.off)));
      }
    });
  }

  void _importQuery() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importar consulta JSON'),
        content: TextField(controller: ctrl, maxLines: 12, decoration: const InputDecoration(border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: ()=>Navigator.pop(ctx, true), child: const Text('Cargar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final spec = importQueryJson(ctrl.text);
      _fromTree(spec.root);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Consulta importada')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al importar: $e')));
    }
  }

  void _exportQuery() {
    final spec = SearchSpec(root: _toTree());
    final text = exportQueryJson(spec);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exportar consulta JSON'),
        content: SingleChildScrollView(child: SelectableText(text)),
        actions: [TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text('Cerrar'))],
      ),
    );
  }

  void _reset() => setState(() {
    _items
      ..clear()
      ..add(_Entry(op: null, clause: const TextClause(element: 'content')));
  });

  void _apply() => Navigator.pop(context, SearchSpec(root: _toTree()));

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
                IconButton(onPressed: _addBlock, icon: const Icon(Icons.add)),
                const SizedBox(width: 4),
                IconButton(onPressed: _importQuery, icon: const Icon(Icons.upload)),
                IconButton(onPressed: _exportQuery, icon: const Icon(Icons.download)),
                const Spacer(),
                IconButton(onPressed: _reset, icon: const Icon(Icons.restart_alt)),
                const SizedBox(width: 8),
                FilledButton(onPressed: _apply, child: const Text('OK')),
                const SizedBox(width: 8),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ]),
              const SizedBox(height: 8),

              for (int i = 0; i < _items.length; i++) ...[
                if (i > 0)
                  Row(
                    children: [
                      const SizedBox(width: 8),
                      const Text('Conector:'),
                      const SizedBox(width: 8),
                      DropdownButton<Op>(
                        value: _items[i].op ?? Op.and,
                        onChanged: (v) => setState(() => _items[i] = _items[i].copyWith(op: v ?? Op.and)),
                        items: const [
                          DropdownMenuItem(value: Op.and, child: Text('AND')),
                          DropdownMenuItem(value: Op.or,  child: Text('OR')),
                        ],
                      ),
                    ],
                  ),
                const SizedBox(height: 6),
                _clauseCard(i, _items[i]),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _clauseCard(int idx, _Entry e) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(e.clause is TextClause ? 'Texto' : 'Bandera', style: const TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            IconButton(onPressed: () => setState(() => _items.removeAt(idx)), icon: const Icon(Icons.delete_outline)),
          ]),
          const SizedBox(height: 8),
          if (e.clause is TextClause)
            _textEditor(e.clause as TextClause, (nc) => setState(() => _items[idx] = e.copyWith(clause: nc))),
          if (e.clause is FlagClause)
            _flagEditor(e.clause as FlagClause, (nc) => setState(() => _items[idx] = e.copyWith(clause: nc))),
        ]),
      ),
    );
  }

  Widget _textEditor(TextClause c, void Function(TextClause) onChange) {
    String element = c.element; // id | content | note
    Tri presence = c.presence;
    List<Token> tokens = [...c.tokens];
    TextMatch match = c.match;

    void setElement(String v) {
      element = v;
      // presence oculto para id: fuerzo off
      if (element == 'id') presence = Tri.off;
      onChange(TextClause(element: element, presence: presence, tokens: tokens, match: match));
    }

    void cyclePresence() {
      if (element == 'id') return; // no aplica
      presence = switch (presence) { Tri.off => Tri.include, Tri.include => Tri.exclude, Tri.exclude => Tri.off };
      onChange(TextClause(element: element, presence: presence, tokens: tokens, match: match));
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
            TextButton(onPressed: ()=>Navigator.pop(dctx, Tri.exclude), child: const Text('Añadir (⊘)')),
            FilledButton(onPressed: ()=>Navigator.pop(dctx, Tri.include), child: const Text('Añadir (+)')),
          ],
        ),
      );
      if (mode == null) return;
      final t = ctrl.text.trim();
      if (t.isEmpty) return;
      tokens = [...tokens, Token(t, mode)];
      onChange(TextClause(element: element, presence: presence, tokens: tokens, match: match));
    }

    void delToken(int i) {
      tokens = [...tokens]..removeAt(i);
      onChange(TextClause(element: element, presence: presence, tokens: tokens, match: match));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Elemento'),
      const SizedBox(height: 6),
      Wrap(spacing: 8, children: [
        ChoiceChip(label: const Text('ID'),       selected: element == 'id',      onSelected: (_)=>setElement('id')),
        ChoiceChip(label: const Text('Contenido'),selected: element == 'content', onSelected: (_)=>setElement('content')),
        ChoiceChip(label: const Text('Notas'),    selected: element == 'note',    onSelected: (_)=>setElement('note')),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        const Text('Presencia'),
        const SizedBox(width: 8),
        if (element == 'id')
          const Text('(no aplica)')
        else
          ActionChip(
            label: Text(switch (presence) { Tri.include => '+Tiene', Tri.exclude => '⊘No tiene', Tri.off => 'Off' }),
            onPressed: cyclePresence,
          ),
      ]),
      const SizedBox(height: 8),
      const Text('Tokens'),
      const SizedBox(height: 6),
      Wrap(spacing: 8, runSpacing: 6, children: [
        for (int i = 0; i < tokens.length; i++)
          InputChip(
            label: Text('${tokens[i].mode == Tri.exclude ? "⊘" : "+"}${tokens[i].t}'),
            onDeleted: () => delToken(i),
          ),
        ActionChip(label: const Text('Añadir token'), onPressed: addToken),
      ]),
      const SizedBox(height: 8),
      const Text('Coincidencia'),
      const SizedBox(height: 6),
      Wrap(spacing: 8, children: [
        ChoiceChip(label: const Text('Contiene'), selected: match == TextMatch.contains, onSelected: (_)=>onChange(TextClause(element: element, presence: presence, tokens: tokens, match: TextMatch.contains))),
        ChoiceChip(label: const Text('Prefijo'),  selected: match == TextMatch.prefix,   onSelected: (_)=>onChange(TextClause(element: element, presence: presence, tokens: tokens, match: TextMatch.prefix))),
        ChoiceChip(label: const Text('Exacto'),   selected: match == TextMatch.exact,    onSelected: (_)=>onChange(TextClause(element: element, presence: presence, tokens: tokens, match: TextMatch.exact))),
      ]),
    ]);
  }

  Widget _flagEditor(FlagClause c, void Function(FlagClause) onChange) {
    String field = c.field;
    Set<String> include = {...c.include};
    Set<String> exclude = {...c.exclude};
    Tri mode = c.mode;
    final anchorCtrl = TextEditingController(text: c.anchorId ?? '');

    void setField(String v) {
      field = v;
      include.clear(); exclude.clear(); mode = Tri.off;
      onChange(FlagClause(field: field, include: include, exclude: exclude, mode: mode, anchorId: anchorCtrl.text.trim()));
    }

    void toggleVal(String v) {
      if (include.contains(v)) { include.remove(v); exclude.add(v); }
      else if (exclude.contains(v)) { exclude.remove(v); }
      else { include.add(v); }
      onChange(FlagClause(field: field, include: include, exclude: exclude, mode: mode, anchorId: anchorCtrl.text.trim()));
    }

    void setMode(Tri v) {
      mode = v;
      onChange(FlagClause(field: field, include: include, exclude: exclude, mode: mode, anchorId: anchorCtrl.text.trim()));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Campo'),
      const SizedBox(height: 6),
      Wrap(spacing: 8, children: [
        ChoiceChip(label: const Text('Tipo'),     selected: field == 'type',     onSelected: (_)=>setField('type')),
        ChoiceChip(label: const Text('Estado'),   selected: field == 'status',   onSelected: (_)=>setField('status')),
        ChoiceChip(label: const Text('Enlaces'),  selected: field == 'hasLinks', onSelected: (_)=>setField('hasLinks')),
        ChoiceChip(label: const Text('Relación'), selected: field == 'relation', onSelected: (_)=>setField('relation')),
      ]),
      const SizedBox(height: 8),

      if (field == 'type') ...[
        const Text('Valores'),
        const SizedBox(height: 6),
        Wrap(spacing: 8, children: [
          _triVal('idea', include, exclude, toggleVal),
          _triVal('action', include, exclude, toggleVal),
        ]),
      ] else if (field == 'status') ...[
        const Text('Valores'),
        const SizedBox(height: 6),
        Wrap(spacing: 8, children: [
          _triVal('normal', include, exclude, toggleVal),
          _triVal('completed', include, exclude, toggleVal),
          _triVal('archived', include, exclude, toggleVal),
        ]),
      ] else if (field == 'hasLinks') ...[
        const Text('Modo'),
        const SizedBox(height: 6),
        Wrap(spacing: 8, children: [
          ChoiceChip(label: const Text('Incluir'), selected: mode == Tri.include, onSelected: (_)=>setMode(Tri.include)),
          ChoiceChip(label: const Text('Excluir'), selected: mode == Tri.exclude, onSelected: (_)=>setMode(Tri.exclude)),
          ChoiceChip(label: const Text('Off'),     selected: mode == Tri.off,     onSelected: (_)=>setMode(Tri.off)),
        ]),
      ] else ...[
        // relation
        const Text('Relacionado con (ID)'),
        const SizedBox(height: 6),
        TextField(
          controller: anchorCtrl,
          decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), hintText: 'p.ej. B1-007'),
          onChanged: (_)=>onChange(FlagClause(field: field, include: include, exclude: exclude, mode: mode, anchorId: anchorCtrl.text.trim())),
        ),
        const SizedBox(height: 8),
        const Text('Modo'),
        const SizedBox(height: 6),
        Wrap(spacing: 8, children: [
          ChoiceChip(label: const Text('Incluir'), selected: mode == Tri.include, onSelected: (_)=>setMode(Tri.include)),
          ChoiceChip(label: const Text('Excluir'), selected: mode == Tri.exclude, onSelected: (_)=>setMode(Tri.exclude)),
          ChoiceChip(label: const Text('Off'),     selected: mode == Tri.off,     onSelected: (_)=>setMode(Tri.off)),
        ]),
      ],
    ]);
  }

  Widget _triVal(String v, Set<String> include, Set<String> exclude, void Function(String) onTap) {
    Color? bg; String label = v;
    if (include.contains(v)) { bg = Colors.green.withOpacity(.15); label = '+$v'; }
    else if (exclude.contains(v)) { bg = Colors.red.withOpacity(.15); label = '⊘$v'; }
    return InkWell(onTap: () => onTap(v), child: Chip(label: Text(label), backgroundColor: bg));
  }
}

class _Entry {
  final Op? op;        // conector ANTES del bloque (null en el primero)
  final Clause clause; // TextClause | FlagClause
  _Entry({required this.op, required this.clause});

  _Entry copyWith({Op? op, Clause? clause}) => _Entry(op: op ?? this.op, clause: clause ?? this.clause);
}
