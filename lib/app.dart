import 'package:flutter/material.dart';
import 'package:caosbox/core/models/enums.dart';
import 'package:caosbox/config/blocks.dart';
import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/ui/screens/generic_screen.dart';
import 'package:caosbox/domain/search/search_models.dart';

class CaosApp extends StatefulWidget {
  const CaosApp({super.key});
  @override State<CaosApp> createState() => _CaosAppState();
}

class _CaosAppState extends State<CaosApp> {
  final st = AppState();
  final Map<ItemType, SearchSpec> _specs = { ItemType.idea: const SearchSpec(), ItemType.action: const SearchSpec() };
  final Map<ItemType, String> _queries = { ItemType.idea: '', ItemType.action: '' };

  @override void dispose(){ st.dispose(); super.dispose(); }

  Future<void> _openFilters(BuildContext ctx, ItemType type) async {
    final seed = (_specs[type] ?? const SearchSpec()).clone();
    final updated = await showModalBottomSheet<SearchSpec>(
      context: ctx, isScrollControlled: true,
      builder: (_) => FiltersSheet(initial: seed, state: st),
    );
    if (updated != null) setState(()=> _specs[type] = updated.clone());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CaosBox (Beta)',
      theme: ThemeData(useMaterial3: true),
      home: DefaultTabController(
        length: blocks.length,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('CaosBox (Beta)'),
            bottom: TabBar(tabs:[for(final b in blocks) Tab(icon:Icon(b.icon),text:b.label)]),
          ),
          body: SafeArea(child: TabBarView(children:[
            for(final b in blocks)
              b.type!=null
                ? GenericScreen(
                    block:b,
                    state:st,
                    spec: _specs[b.type!] ?? const SearchSpec(),
                    quickQuery: _queries[b.type!] ?? '',
                    onQuickQuery:(q)=> setState(()=> _queries[b.type!] = q),
                    onOpenFilters:(BuildContext ctx, ItemType t)=>_openFilters(ctx, t),
                  )
                : b.custom!(context, st),
          ])),
          // sin FAB: el alta está dentro de cada pestaña con ComposerCard
        ),
      ),
    );
  }
}

/* ----------------- FiltersSheet (igual que tu versión con chip Enlaces dentro de “Tipo”) ----------------- */
import 'package:caosbox/search/search_io.dart';
import 'package:caosbox/core/utils/tri.dart';
import 'package:caosbox/ui/widgets/tri_pill.dart';
import 'package:caosbox/domain/search/search_engine.dart'; // (para tipos)
import 'package:caosbox/app/state/app_state.dart';

class FiltersSheet extends StatefulWidget{
  final SearchSpec initial; final AppState state;
  const FiltersSheet({super.key,required this.initial,required this.state});
  @override State<FiltersSheet> createState()=>_FiltersSheetState();
}

class _FiltersSheetState extends State<FiltersSheet>{
  late List<Clause> clauses;
  @override void initState(){ super.initState(); clauses=widget.initial.clauses.map((c)=>c.clone()).toList(); }

  Future<void> _addBlock() async {
    final chose = await showModalBottomSheet<String>(
      context: context, builder: (_)=>SafeArea(child: Wrap(children:[
        ListTile(leading:const Icon(Icons.category), title:const Text('Tipo / Relación'), onTap:(){Navigator.pop(context,'type');}),
        ListTile(leading:const Icon(Icons.flag),     title:const Text('Estado'),          onTap:(){Navigator.pop(context,'status');}),
        ListTile(leading:const Icon(Icons.text_fields), title:const Text('Texto'),       onTap:(){Navigator.pop(context,'text');}),
      ])));
    if(chose==null) return;
    setState(()=>clauses.add(chose=='text'?TextClause():EnumClause(field:chose)));
  }

  EnumClause? _readHasLinks(){
    for(final c in clauses){ if(c is EnumClause && c.field=='hasLinks') return c; }
    return null;
  }
  void _writeHasLinks(EnumClause? v){
    setState((){
      int idx=-1;
      for(int i=0;i<clauses.length;i++){
        final c=clauses[i]; if(c is EnumClause && c.field=='hasLinks'){ idx=i; break; }
      }
      if(v==null){ if(idx!=-1) clauses.removeAt(idx); }
      else{ if(idx==-1) clauses.add(v); else clauses[idx]=v; }
    });
  }

  void _exportQuery(){ final json = exportQueryJson(SearchSpec(clauses:clauses)); _showLong('Búsqueda (JSON)', json); }
  Future<void> _importQuery() async {
    final t=TextEditingController();
    final ok = await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
      title:const Text('Importar búsqueda (JSON)'),
      content:TextField(controller:t,maxLines:14,decoration:const InputDecoration(border:OutlineInputBorder(),hintText:'Pega aquí la búsqueda…')),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancelar')),
               FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Cargar'))],
    ));
    if(ok==true){
      try{
        final s = importQueryJson(t.text);
        setState(()=>clauses=[...s.clauses.map((c)=>c.clone())]);
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Búsqueda cargada')));
      }catch(e){ if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Error: $e'))); }
    }
  }

  @override
  Widget build(BuildContext context){
    final visible = clauses.where((c) => !(c is EnumClause && c.field == 'hasLinks')).toList();
    return SafeArea(
      child: DraggableScrollableSheet(
        expand:false, initialChildSize:.9,
        builder:(_,ctrl)=>Material(child: Column(children:[
          Padding(
            padding: const EdgeInsets.fromLTRB(8,8,8,8),
            child: Align(
              alignment: Alignment.centerRight,
              child: Wrap(spacing: 2, runSpacing: 2, crossAxisAlignment: WrapCrossAlignment.center, children: [
                IconButton(tooltip:'Añadir bloque',   onPressed:_addBlock,     icon:const Icon(Icons.add)),
                IconButton(tooltip:'Exportar búsqueda',onPressed:_exportQuery, icon:const Icon(Icons.upload)),
                IconButton(tooltip:'Importar búsqueda',onPressed:_importQuery, icon:const Icon(Icons.download)),
                IconButton(tooltip:'Limpiar',          onPressed:()=>setState(()=>clauses.clear()), icon:const Icon(Icons.clear_all)),
                IconButton(tooltip:'Aplicar',          onPressed:()=>Navigator.pop(context,SearchSpec(clauses:clauses.map((c)=>c.clone()).toList())), icon:const Icon(Icons.check)),
              ]),
            ),
          ),
          const Divider(height:1),
          Expanded(child: ListView(controller:ctrl,padding:const EdgeInsets.all(12), children:[
            for(final c in visible)
              Padding(
                padding: const EdgeInsets.only(bottom:12),
                child: _ClauseEditor(
                  clause: c,
                  onRemove: ()=> setState(()=> clauses.remove(c)),
                  onUpdate: (nc){
                    final idx = clauses.indexOf(c);
                    if (idx != -1) setState(()=> clauses[idx] = nc);
                  },
                  readHasLinks: _readHasLinks,
                  writeHasLinks: _writeHasLinks,
                ),
              ),
          ])),
        ])),
      ),
    );
  }

  void _showLong(String title,String text){
    showDialog(context:context,builder:(ctx)=>AlertDialog(
      title:Text(title), content:SizedBox(width:600, child:SelectableText(text)),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cerrar'))],
    ));
  }
}

class _ClauseEditor extends StatefulWidget{
  final Clause clause; final VoidCallback onRemove; final ValueChanged<Clause> onUpdate;
  final EnumClause? Function()? readHasLinks;
  final void Function(EnumClause?)? writeHasLinks;
  const _ClauseEditor({required this.clause,required this.onRemove,required this.onUpdate,this.readHasLinks,this.writeHasLinks});
  @override State<_ClauseEditor> createState()=>_ClauseEditorState();
}
class _ClauseEditorState extends State<_ClauseEditor>{
  bool open=true;

  @override
  Widget build(BuildContext context){
    final c = widget.clause;
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        ListTile(
          title: Text(_title(c)), subtitle: Text(_summary(c)),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(onPressed: ()=> setState(()=> open=!open), icon: Icon(open?Icons.expand_less:Icons.expand_more)),
            IconButton(onPressed: widget.onRemove, icon: const Icon(Icons.close)),
          ]),
        ),
        if(open) const Divider(height:1),
        if(open) Padding(padding: const EdgeInsets.all(12), child: _body(c)),
      ]),
    );
  }

  String _title(Clause c) => c is EnumClause ? (switch(c.field){'type'=>'Tipo / Relación','status'=>'Estado','hasLinks'=>'Relación',_=>'Enum'}) : 'Texto';
  String _summary(Clause c){
    if (c is EnumClause) return 'incluye=${c.include.join(",")} excluye=${c.exclude.join(",")}';
    final tc = c as TextClause;
    final f = tc.fields.entries.map((e)=>'${e.key}:${(e.value).name}').join(' ');
    final t = tc.tokens.map((x)=>(x.mode==Tri.exclude?'-':'')+x.t).join(' ');
    return '"$t" en: $f';
  }

  Widget _body(Clause c){
    if (c is EnumClause) {
      if (c.field == 'type') {
        final chipsTipo = ['idea','action'].map((v)=> TriPill(
          label:v, mode: _mode(c,v),
          onTap: (){
            setState((){
              final next = _next(_mode(c,v));
              c.include.remove(v); c.exclude.remove(v);
              if (next == Tri.include) c.include.add(v);
              if (next == Tri.exclude) c.exclude.add(v);
              widget.onUpdate(c);
            });
          },
        ));

        final hl = widget.readHasLinks?.call();
        final mode = hl == null ? Tri.off : _mode(hl, 'true');
        final chipEnlaces = TriPill(
          label: 'enlaces', mode: mode,
          onTap: () {
            final next = _next(mode);
            EnumClause? nv;
            if (next != Tri.off) {
              nv = EnumClause(field:'hasLinks');
              if (next == Tri.include) nv.include.add('true'); // con enlaces
              if (next == Tri.exclude) nv.exclude.add('true'); // sin enlaces
            }
            widget.writeHasLinks?.call(nv);
            setState((){});
          },
        );

        return Wrap(spacing:8, runSpacing:8, children: [...chipsTipo, const SizedBox(width:16), chipEnlaces]);
      }

      final values = switch(c.field){ 'status'=>['normal','completed','archived'], 'hasLinks'=>['true'], _=> <String>[] };
      return Wrap(spacing:8, runSpacing:8, children: [
        for (final v in values) TriPill(
          label: v, mode: _mode(c,v),
          onTap: (){
            setState((){
              final next = _next(_mode(c,v));
              c.include.remove(v); c.exclude.remove(v);
              if (next == Tri.include) c.include.add(v);
              if (next == Tri.exclude) c.exclude.add(v);
              widget.onUpdate(c);
            });
          },
        ),
      ]);
    }

    final tc = c as TextClause;
    final t = TextEditingController(text: tc.tokens.map((x)=>(x.mode==Tri.exclude?'-':'')+x.t).join(' '));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Consulta (usa "-" para excluir)'),
      const SizedBox(height:6),
      TextField(controller: t, minLines: 1, maxLines: 3, decoration: const InputDecoration(border: OutlineInputBorder())),
      const SizedBox(height:10), const Text('Alcances'), const SizedBox(height:6),
      Wrap(spacing:8, children: [
        for (final k in ['id','content','note'])
          TriPill(label:k, mode: tc.fields[k]??Tri.off, onTap: (){
            setState(()=> tc.fields[k] = _next(tc.fields[k]??Tri.off));
            widget.onUpdate(tc);
          }),
      ]),
      const SizedBox(height:12),
      Align(alignment: Alignment.centerRight, child: ElevatedButton(
        onPressed: (){
          final parts = t.text.trim().isEmpty ? <String>[] : t.text.trim().split(RegExp(r'\s+'));
          tc.tokens..clear()..addAll(parts.map((p)=> p.startsWith('-')&&p.length>1 ? Token(p.substring(1),Tri.exclude) : Token(p,Tri.include)));
          widget.onUpdate(tc);
        }, child: const Text('Aplicar'),
      )),
    ]);
  }

  Tri _mode(EnumClause c, String v){ if(c.include.contains(v))return Tri.include; if(c.exclude.contains(v))return Tri.exclude; return Tri.off; }
  Tri _next(Tri m)=> switch(m){Tri.off=>Tri.include,Tri.include=>Tri.exclude,Tri.exclude=>Tri.off};
}
