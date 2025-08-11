import 'package:flutter/material.dart';
import 'config/blocks.dart';
import 'models/enums.dart';
import 'state/app_state.dart';
import 'ui/screens/generic_screen.dart';
import 'search/search_models.dart';
import 'search/search_io.dart';

class CaosApp extends StatefulWidget {
  const CaosApp({super.key});
  @override State<CaosApp> createState() => _CaosAppState();
}

class _CaosAppState extends State<CaosApp> {
  final st = AppState();
  SearchSpec spec = const SearchSpec();
  String quickQuery = '';
  @override void dispose(){ st.dispose(); super.dispose(); }

  Future<void> _openFilters(BuildContext ctx) async {
    final seed = spec.clone();
    final updated = await showModalBottomSheet<SearchSpec>(
      context: ctx, isScrollControlled: true,
      builder: (_) => FiltersSheet(initial: seed, state: st),
    );
    if (updated != null) setState(() => spec = updated.clone());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CaosBox (Beta)',
      theme: ThemeData(useMaterial3: true),
      home: DefaultTabController(
        length: blocks.length,
        child: _HomeScaffold(
          st: st,
          spec: spec,
          quickQuery: quickQuery,
          onQuickQuery: (q) => setState(()=>quickQuery=q),
          onOpenFilters: _openFilters,
        ),
      ),
    );
  }
}

/* ---------- Scaffold bajo el DefaultTabController ---------- */
class _HomeScaffold extends StatefulWidget {
  final AppState st;
  final SearchSpec spec;
  final String quickQuery;
  final ValueChanged<String> onQuickQuery;
  final Future<void> Function(BuildContext) onOpenFilters;
  const _HomeScaffold({required this.st,required this.spec,required this.quickQuery,required this.onQuickQuery,required this.onOpenFilters});
  @override State<_HomeScaffold> createState()=>_HomeScaffoldState();
}
class _HomeScaffoldState extends State<_HomeScaffold>{
  TabController? _tab; int _tabIndex=0;
  @override void didChangeDependencies(){ super.didChangeDependencies(); final t=DefaultTabController.of(context);
    if(_tab!=t){ _tab?.removeListener(_onTab); _tab=t; if(_tab!=null){ _tabIndex=_tab!.index; _tab!.addListener(_onTab);} } }
  void _onTab(){ if(!mounted||_tab==null)return; if(_tabIndex!=_tab!.index) setState(()=>_tabIndex=_tab!.index); }
  @override void dispose(){ _tab?.removeListener(_onTab); super.dispose(); }

  @override Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text('CaosBox (Beta)'),
        bottom: TabBar(tabs:[for(final b in blocks) Tab(icon:Icon(b.icon),text:b.label)]),
      ),
      body: SafeArea(child: TabBarView(children:[
        for(final b in blocks)
          b.type!=null
            ? GenericScreen(
                block:b, state:widget.st, spec:widget.spec, quickQuery:widget.quickQuery,
                onQuickQuery:widget.onQuickQuery, onOpenFilters:widget.onOpenFilters,
              )
            : b.custom!(context, widget.st),
      ])),
      floatingActionButton: (blocks[_tabIndex].type==null)?null
        : FloatingActionButton(onPressed:()=>_openAddSheet(context,blocks[_tabIndex].type!), child:const Icon(Icons.add)),
    );
  }

  void _openAddSheet(BuildContext context, ItemType type){
    final c=TextEditingController();
    showModalBottomSheet(
      context:context,isScrollControlled:true,
      builder:(ctx)=>Padding(
        padding:EdgeInsets.only(bottom:MediaQuery.of(ctx).viewInsets.bottom,left:16,right:16,top:16),
        child:SafeArea(top:false,child:Column(mainAxisSize:MainAxisSize.min,children:[
          Row(children:[
            Icon(type==ItemType.idea?Icons.lightbulb:Icons.assignment), const SizedBox(width:8),
            Text(type==ItemType.idea?'Nueva idea':'Nueva acción',style:const TextStyle(fontWeight:FontWeight.bold)),
            const Spacer(), IconButton(icon:const Icon(Icons.close),onPressed:()=>Navigator.pop(ctx)),
          ]),
          const SizedBox(height:8),
          TextField(controller:c,autofocus:true,minLines:1,maxLines:8,
            decoration:InputDecoration(hintText:type==ItemType.idea?'Escribe tu idea...':'Describe la acción...',border:const OutlineInputBorder())),
          const SizedBox(height:12),
          Row(mainAxisAlignment:MainAxisAlignment.end,children:[
            TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancelar')),
            const SizedBox(width:8),
            ElevatedButton(onPressed:(){ if(c.text.trim().isEmpty)return; widget.st.add(type,c.text); Navigator.pop(ctx); },child:const Text('Agregar')),
          ]),
          const SizedBox(height:12),
        ])),
      ),
    );
  }
}

/* ================== Hoja de filtros (avanzado) ================== */
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
        ListTile(leading:const Icon(Icons.category),    title:const Text('Tipo (enum)'),   onTap:(){Navigator.pop(context,'type');}),
        ListTile(leading:const Icon(Icons.flag),        title:const Text('Estado (enum)'), onTap:(){Navigator.pop(context,'status');}),
        ListTile(leading:const Icon(Icons.link),        title:const Text('Relación'),      onTap:(){Navigator.pop(context,'hasLinks');}),
        ListTile(leading:const Icon(Icons.text_fields), title:const Text('Texto'),         onTap:(){Navigator.pop(context,'text');}),
      ])));
    if(chose==null) return;
    setState(()=>clauses.add(chose=='text'?TextClause():EnumClause(field:chose)));
  }

  void _exportQuery(){
    final json = exportQueryJson(SearchSpec(clauses:clauses));
    _showLong('Búsqueda (JSON)', json);
  }

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
      }catch(e){
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context){
    return SafeArea(
      child: DraggableScrollableSheet(
        expand:false, initialChildSize:.9,
        builder:(_,ctrl)=>Material(
          child: Column(children:[
            // Cabecera compacta: solo iconos, con Wrap para evitar desbordes
            Padding(
              padding: const EdgeInsets.fromLTRB(8,8,8,8),
              child: Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 2, runSpacing: 2, crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Añadir bloque',
                      onPressed: _addBlock,
                      icon: const Icon(Icons.add),
                    ),
                    IconButton(
                      tooltip: 'Exportar búsqueda',
                      onPressed: _exportQuery,
                      icon: const Icon(Icons.upload),
                    ),
                    IconButton(
                      tooltip: 'Importar búsqueda',
                      onPressed: _importQuery,
                      icon: const Icon(Icons.download),
                    ),
                    IconButton(
                      tooltip: 'Limpiar',
                      onPressed: () => setState(()=>clauses.clear()),
                      icon: const Icon(Icons.clear_all),
                    ),
                    IconButton(
                      tooltip: 'Aplicar',
                      onPressed: () => Navigator.pop(
                        context, SearchSpec(clauses:clauses.map((c)=>c.clone()).toList()),
                      ),
                      icon: const Icon(Icons.check),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height:1),
            Expanded(child: ListView(controller:ctrl,padding:const EdgeInsets.all(12), children:[
              for(int i=0;i<clauses.length;i++)
                Padding(padding:const EdgeInsets.only(bottom:12), child:_ClauseEditor(
                  clause:clauses[i],
                  onRemove:()=>setState(()=>clauses.removeAt(i)),
                  onUpdate:(nc)=>setState(()=>clauses[i]=nc),
                )),
            ])),
          ]),
        ),
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

/* ===== Editor de bloque (sin cambios funcionales relevantes) ===== */
class _ClauseEditor extends StatefulWidget{
  final Clause clause; final VoidCallback onRemove; final ValueChanged<Clause> onUpdate;
  const _ClauseEditor({required this.clause,required this.onRemove,required this.onUpdate});
  @override State<_ClauseEditor> createState()=>_ClauseEditorState();
}
class _ClauseEditorState extends State<_ClauseEditor>{
  bool open=true;
  @override Widget build(BuildContext context){
    final c=widget.clause;
    return Container(
      decoration:BoxDecoration(border:Border.all(color:Colors.black12),borderRadius:BorderRadius.circular(8)),
      child:Column(children:[
        ListTile(
          title:Text(_title(c)), subtitle:Text(_summary(c)),
          trailing:Row(mainAxisSize:MainAxisSize.min,children:[
            IconButton(onPressed:()=>setState(()=>open=!open),icon:Icon(open?Icons.expand_less:Icons.expand_more)),
            IconButton(onPressed:widget.onRemove, icon:const Icon(Icons.close)),
          ]),
        ),
        if(open)const Divider(height:1),
        if(open)Padding(padding:const EdgeInsets.all(12),child:_body(c)),
      ]),
    );
  }

  String _title(Clause c)=> c is EnumClause ? (switch(c.field){'type'=>'Tipo','status'=>'Estado','hasLinks'=>'Relación',_=>'Enum'}) : 'Texto';
  String _summary(Clause c){
    if(c is EnumClause){ return 'incluye=${c.include.join(",")} excluye=${c.exclude.join(",")}'; }
    final tc=c as TextClause;
    final f=tc.fields.entries.map((e)=>'${e.key}:${_triStr(e.value)}').join(' ');
    final t=tc.tokens.map((x)=>(x.mode==Tri.exclude?'-':'')+x.t).join(' ');
    return '"$t" en: $f';
  }

  Widget _body(Clause c){
    if(c is EnumClause){
      if(c.field=='hasLinks'){
        Tri _invert(Tri m)=>switch(m){Tri.include=>Tri.exclude,Tri.exclude=>Tri.include,_=>Tri.off};
        final m=_mode(c,'true');
        return Wrap(spacing:8,runSpacing:8,children:[
          _TriPill(label:'Con enlaces',mode:m,onTap:(){
            setState((){
              final next=_next(m); c.include.remove('true'); c.exclude.remove('true');
              if(next==Tri.include)c.include.add('true'); if(next==Tri.exclude)c.exclude.add('true');
              widget.onUpdate(c);
            });
          }),
          _TriPill(label:'Sin enlaces',mode:_invert(m),onTap:(){
            setState((){
              final next=_next(_invert(m)); final write=_invert(next);
              c.include.remove('true'); c.exclude.remove('true');
              if(write==Tri.include)c.include.add('true'); if(write==Tri.exclude)c.exclude.add('true');
              widget.onUpdate(c);
            });
          }),
        ]);
      }
      final values = switch(c.field){ 'type'=>['idea','action'], 'status'=>['normal','completed','archived'], _=> <String>[] };
      return Wrap(spacing:8,runSpacing:8,children:[
        for(final v in values)
          _TriPill(label:v, mode:_mode(c,v), onTap:(){
            setState((){
              final next=_next(_mode(c,v)); c.include.remove(v); c.exclude.remove(v);
              if(next==Tri.include)c.include.add(v); if(next==Tri.exclude)c.exclude.add(v);
              widget.onUpdate(c);
            });
          }),
      ]);
    }
    final tc=c as TextClause;
    final t=TextEditingController(text:tc.tokens.map((x)=>(x.mode==Tri.exclude?'-':'')+x.t).join(' '));
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('Consulta (usa "-" para excluir)'),
      const SizedBox(height:6),
      TextField(controller:t,minLines:1,maxLines:3,decoration:const InputDecoration(border:OutlineInputBorder())),
      const SizedBox(height:10), const Text('Alcances'), const SizedBox(height:6),
      Wrap(spacing:8,children:[
        for(final k in ['id','content','note'])
          _TriPill(label:k,mode:tc.fields[k]??Tri.off,onTap:(){
            setState((){ tc.fields[k]=_next(tc.fields[k]??Tri.off); widget.onUpdate(tc); });
          }),
      ]),
      const SizedBox(height:12),
      Align(alignment:Alignment.centerRight,child:ElevatedButton(
        onPressed:(){ final parts=t.text.trim().isEmpty? <String>[] : t.text.trim().split(RegExp(r'\s+'));
          tc.tokens..clear()..addAll(parts.map((p)=> p.startsWith('-')&&p.length>1 ? Token(p.substring(1),Tri.exclude):Token(p,Tri.include)));
          widget.onUpdate(tc);
        }, child:const Text('Aplicar texto'),
      )),
    ]);
  }

  Tri _mode(EnumClause c,String v){ if(c.include.contains(v))return Tri.include; if(c.exclude.contains(v))return Tri.exclude; return Tri.off; }
  Tri _next(Tri m)=> switch(m){Tri.off=>Tri.include,Tri.include=>Tri.exclude,Tri.exclude=>Tri.off};
  String _triStr(Tri t)=> switch(t){Tri.off=>'off',Tri.include=>'include',Tri.exclude=>'exclude'};
}

class _TriPill extends StatelessWidget{
  final String label; final Tri mode; final VoidCallback onTap;
  const _TriPill({required this.label,required this.mode,required this.onTap});
  @override Widget build(BuildContext context){
    Color? bg; if(mode==Tri.include)bg=Colors.green.withOpacity(.15); if(mode==Tri.exclude)bg=Colors.red.withOpacity(.15);
    return InkWell(
      onTap:onTap,
      child: Container(
        padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),
        decoration:BoxDecoration(color:bg,border:Border.all(color:Colors.black26),borderRadius:BorderRadius.circular(999)),
        child: Row(mainAxisSize:MainAxisSize.min,children:[
          if(mode==Tri.include)const Icon(Icons.check,size:14),
          if(mode==Tri.exclude)const Icon(Icons.block,size:14),
          if(mode!=Tri.off)const SizedBox(width:4),
          Text(label),
        ]),
      ),
    );
  }
}
