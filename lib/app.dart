import 'package:flutter/material.dart';
import 'config/blocks.dart';
import 'models/enums.dart';
import 'state/app_state.dart';
import 'ui/screens/generic_screen.dart';

// motor + IO (ya los tienes)
import 'search/search_models.dart';
import 'search/search_io.dart';

class CaosApp extends StatefulWidget {
  const CaosApp({super.key});
  @override State<CaosApp> createState() => _CaosAppState();
}

class _CaosAppState extends State<CaosApp> {
  final st = AppState();

  // Búsqueda avanzada (bloques)
  SearchSpec spec = const SearchSpec();
  // Búsqueda rápida (🔎)
  String quickQuery = '';

  @override void dispose() { st.dispose(); super.dispose(); }

  Future<void> _openFilters() async {
    final updated = await showModalBottomSheet<SearchSpec>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FiltersSheet(initial: spec, state: st),
    );
    if (updated != null) setState(() => spec = updated);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CaosBox (Beta)',
      theme: ThemeData(useMaterial3: true),
      home: AnimatedBuilder(
        animation: st,
        builder: (_, __) => DefaultTabController(
          length: blocks.length,
          child: Builder(builder: (ctxWithTab) {
            final tabCtrl = DefaultTabController.of(ctxWithTab);
            return AnimatedBuilder(
              animation: tabCtrl.animation!,
              builder: (ctx, __) {
                final idx = tabCtrl.index;
                final b = blocks[idx];
                final showFab = b.type != null; // solo Ideas/Acciones

                return Scaffold(
                  appBar: AppBar(
                    title: const Text('CaosBox (Beta)'),
                    bottom: TabBar(
                      tabs: [for (final bb in blocks) Tab(icon: Icon(bb.icon), text: bb.label)],
                    ),
                  ),
                  body: SafeArea(
                    child: TabBarView(
                      children: [
                        for (final bb in blocks)
                          bb.type != null
                              ? GenericScreen(
                                  block: bb,
                                  state: st,
                                  spec: spec,
                                  quickQuery: quickQuery,
                                  onQuickQuery: (q) => setState(() => quickQuery = q),
                                  onOpenFilters: _openFilters,
                                )
                              : bb.custom!(context, st),
                      ],
                    ),
                  ),
                  floatingActionButton: showFab
                      ? FloatingActionButton(
                          onPressed: () => _openAddSheet(ctx, b.type!),
                          child: const Icon(Icons.add),
                        )
                      : null,
                );
              },
            );
          }),
        ),
      ),
    );
  }

  // FAB para agregar
  void _openAddSheet(BuildContext context, ItemType type) {
    final c = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16, right: 16, top: 16,
        ),
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Icon(type == ItemType.idea ? Icons.lightbulb : Icons.assignment),
              const SizedBox(width: 8),
              Text(type == ItemType.idea ? 'Nueva idea' : 'Nueva acción',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(ctx)),
            ]),
            const SizedBox(height: 8),
            TextField(
              controller: c, autofocus: true, minLines: 1, maxLines: 8,
              decoration: InputDecoration(
                hintText: type == ItemType.idea ? 'Escribe tu idea...' : 'Describe la acción...',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (c.text.trim().isEmpty) return;
                  st.add(type, c.text);
                  Navigator.pop(ctx);
                },
                child: const Text('Agregar'),
              ),
            ]),
            const SizedBox(height: 12),
          ]),
        ),
      ),
    );
  }
}

/* ============= Hoja de filtros (avanzado) ============= */
class FiltersSheet extends StatefulWidget {
  final SearchSpec initial;
  final AppState state;
  const FiltersSheet({super.key, required this.initial, required this.state});
  @override State<FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<FiltersSheet> {
  late List<Clause> clauses;
  @override void initState(){ super.initState(); clauses = [...widget.initial.clauses]; }

  void _addBlock() async {
    await showModalBottomSheet(context: context, builder: (_) {
      return SafeArea(child: Wrap(children: [
        ListTile(title: const Text('Bloque: Tipo (enum)'),
          leading: const Icon(Icons.category),
          onTap: (){ setState(()=>clauses.add(EnumClause(field:'type'))); Navigator.pop(context); }),
        ListTile(title: const Text('Bloque: Estado (enum)'),
          leading: const Icon(Icons.flag),
          onTap: (){ setState(()=>clauses.add(EnumClause(field:'status'))); Navigator.pop(context); }),
        ListTile(title: const Text('Bloque: Relaciones (hasLinks)'),
          leading: const Icon(Icons.link),
          onTap: (){ setState(()=>clauses.add(EnumClause(field:'hasLinks'))); Navigator.pop(context); }),
        ListTile(title: const Text('Bloque: Texto'),
          leading: const Icon(Icons.text_fields),
          onTap: (){ setState(()=>clauses.add(TextClause())); Navigator.pop(context); }),
      ]));
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        builder: (_, controller) => Material(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16,12,8,8),
              child: Row(children: [
                const Text('Filtrar / Buscar (avanzado)', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(onPressed: _addBlock, icon: const Icon(Icons.add), label: const Text('Añadir bloque')),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => setState(()=> clauses.clear()),
                  child: const Text('Limpiar'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: (){
                    Navigator.pop(context, SearchSpec(clauses: clauses));
                  },
                  child: const Text('Aplicar'),
                ),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(12),
                children: [
                  for (int i=0;i<clauses.length;i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ClauseEditor(
                        clause: clauses[i],
                        onRemove: ()=> setState(()=>clauses.removeAt(i)),
                        onUpdate: (nc)=> setState(()=>clauses[i]=nc),
                      ),
                    ),
                  const SizedBox(height: 8),
                  const Divider(),
                  // === JSON búsqueda ===
                  const ListTile(title: Text('Búsqueda (JSON)')),
                  Wrap(spacing: 8, children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.visibility),
                      label: const Text('Ver / Copiar JSON'),
                      onPressed: (){
                        final json = exportQueryJson(SearchSpec(clauses: clauses));
                        _showLongText(context, 'Búsqueda (JSON)', json);
                      },
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.paste),
                      label: const Text('Pegar JSON y Cargar'),
                      onPressed: () async {
                        final ctrl = TextEditingController();
                        final ok = await showDialog<bool>(context: context, builder: (ctx){
                          return AlertDialog(
                            title: const Text('Pega aquí la búsqueda (JSON)'),
                            content: TextField(controller: ctrl, maxLines: 14, decoration: const InputDecoration(border: OutlineInputBorder())),
                            actions: [
                              TextButton(onPressed: ()=>Navigator.pop(ctx,false), child: const Text('Cancelar')),
                              FilledButton(onPressed: ()=>Navigator.pop(ctx,true), child: const Text('Cargar')),
                            ],
                          );
                        });
                        if(ok==true){
                          try{
                            final spec = importQueryJson(ctrl.text);
                            setState(()=> clauses = [...spec.clauses]);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Búsqueda cargada')));
                          }catch(e){
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        }
                      },
                    ),
                  ]),
                  const SizedBox(height: 16),
                  const Divider(),
                  // === Datos ===
                  const ListTile(title: Text('Datos (JSON)')),
                  Wrap(spacing: 8, children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.upload),
                      label: const Text('Exportar datos'),
                      onPressed: (){
                        final json = exportDataJson(widget.state);
                        _showLongText(context, 'Datos (JSON)', json);
                      },
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.download),
                      label: const Text('Importar datos (reemplazar)'),
                      onPressed: () async {
                        final ctrl = TextEditingController();
                        final ok = await showDialog<bool>(context: context, builder: (ctx){
                          return AlertDialog(
                            title: const Text('Importar datos (reemplazo)'),
                            content: TextField(controller: ctrl, maxLines: 14, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Pega aquí el JSON de datos…')),
                            actions: [
                              TextButton(onPressed: ()=>Navigator.pop(ctx,false), child: const Text('Cancelar')),
                              FilledButton(onPressed: ()=>Navigator.pop(ctx,true), child: const Text('Importar')),
                            ],
                          );
                        });
                        if(ok==true){
                          try{
                            importDataJsonReplace(widget.state, ctrl.text);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Datos importados')));
                          }catch(e){
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        }
                      },
                    ),
                  ]),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showLongText(BuildContext context, String title, String text){
    showDialog(context: context, builder: (ctx){
      return AlertDialog(
        title: Text(title),
        content: SizedBox(width: 600, child: SelectableText(text)),
        actions: [ TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text('Cerrar')) ],
      );
    });
  }
}

/* ============= Editor de bloque (igual a lo acordado) ============= */
class _ClauseEditor extends StatefulWidget{
  final Clause clause;
  final VoidCallback onRemove;
  final ValueChanged<Clause> onUpdate;
  const _ClauseEditor({required this.clause, required this.onRemove, required this.onUpdate});
  @override State<_ClauseEditor> createState()=>_ClauseEditorState();
}
class _ClauseEditorState extends State<_ClauseEditor>{
  bool open=true;

  @override Widget build(BuildContext context) {
    final c = widget.clause;
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        ListTile(
          title: Text(_title(c)),
          subtitle: Text(_summary(c)),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(onPressed: ()=>setState(()=>open=!open), icon: Icon(open?Icons.expand_less:Icons.expand_more)),
            IconButton(onPressed: widget.onRemove, icon: const Icon(Icons.close)),
          ]),
        ),
        if(open) const Divider(height:1),
        if(open) Padding(padding: const EdgeInsets.all(12), child: _body(c)),
      ]),
    );
  }

  String _title(Clause c){
    if(c is EnumClause){
      switch (c.field){ case 'type': return 'Tipo'; case 'status': return 'Estado'; case 'hasLinks': return 'Relaciones'; }
    }
    return 'Texto';
  }

  String _summary(Clause c){
    if(c is EnumClause){
      return 'incluye=${c.include.join(",")} excluye=${c.exclude.join(",")}';
    } else if(c is TextClause){
      final fields = c.fields.entries.map((e)=> '${e.key}:${_triToStr(e.value)}').join(' ');
      final toks = c.tokens.map((t)=> (t.mode==Tri.exclude?'-':'')+t.t).join(' ');
      return '"$toks"  en: $fields';
    }
    return '';
  }

  Widget _body(Clause c){
    if(c is EnumClause){
      final values = switch (c.field){
        'type'     => ['idea','action'],
        'status'   => ['normal','completed','archived'],
        'hasLinks' => ['true'],
        _ => <String>[],
      };
      return Wrap(spacing:8, runSpacing:8, children: [
        for(final v in values)
          _TriPill(
            label: v,
            mode: _currentMode(c, v),
            onTap: (){
              final next = _next(_currentMode(c, v));
              setState((){
                _setMode(c, v, next);
                widget.onUpdate(c);
              });
            },
          ),
      ]);
    } else if(c is TextClause){
      final ctrl = TextEditingController(text: c.tokens.map((t)=> (t.mode==Tri.exclude?'-':'')+t.t).join(' '));
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Consulta (tokens; usa "-" para excluir)'),
        const SizedBox(height:6),
        TextField(controller: ctrl, minLines:1, maxLines:3, decoration: const InputDecoration(border: OutlineInputBorder())),
        const SizedBox(height:10),
        const Text('Alcances'),
        const SizedBox(height:6),
        Wrap(spacing:8, children: [
          for(final k in ['id','content','note'])
            _TriPill(
              label: k,
              mode: c.fields[k] ?? Tri.off,
              onTap: (){
                final next = _next(c.fields[k] ?? Tri.off);
                setState((){
                  c.fields[k]=next;
                  widget.onUpdate(c);
                });
              },
            ),
        ]),
        const SizedBox(height:12),
        Align(alignment: Alignment.centerRight, child:
          ElevatedButton(onPressed: (){
            final raw = ctrl.text.trim();
            final parts = raw.isEmpty? <String>[] : raw.split(RegExp(r'\s+'));
            c.tokens
              ..clear()
              ..addAll(parts.map((p){
                if(p.startsWith('-') && p.length>1){ return Token(p.substring(1), Tri.exclude); }
                return Token(p, Tri.include);
              }));
            widget.onUpdate(c);
          }, child: const Text('Aplicar texto'))),
      ]);
    }
    return const SizedBox.shrink();
  }

  Tri _currentMode(EnumClause c, String v){
    if(c.include.contains(v)) return Tri.include;
    if(c.exclude.contains(v)) return Tri.exclude;
    return Tri.off;
  }
  void _setMode(EnumClause c, String v, Tri to){
    c.include.remove(v); c.exclude.remove(v);
    if(to==Tri.include) c.include.add(v);
    if(to==Tri.exclude) c.exclude.add(v);
  }
  Tri _next(Tri m)=> switch(m){ Tri.off=>Tri.include, Tri.include=>Tri.exclude, Tri.exclude=>Tri.off };
  String _triToStr(Tri t)=> switch(t){ Tri.off=>'off', Tri.include=>'include', Tri.exclude=>'exclude' };
}

class _TriPill extends StatelessWidget{
  final String label; final Tri mode; final VoidCallback onTap;
  const _TriPill({required this.label, required this.mode, required this.onTap});
  @override Widget build(BuildContext context){
    Color? bg;
    if(mode==Tri.include) bg = Colors.green.withOpacity(.15);
    if(mode==Tri.exclude) bg = Colors.red.withOpacity(.15);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal:10, vertical:6),
        decoration: BoxDecoration(
          color: bg, border: Border.all(color: Colors.black26), borderRadius: BorderRadius.circular(999),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if(mode==Tri.include) const Icon(Icons.check, size:14),
          if(mode==Tri.exclude) const Icon(Icons.block, size:14),
          if(mode!=Tri.off) const SizedBox(width:4),
          Text(label),
        ]),
      ),
    );
  }
}
