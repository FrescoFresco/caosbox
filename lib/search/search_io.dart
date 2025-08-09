import 'dart:convert';
import '../models/item.dart';
import '../models/enums.dart';
import '../state/app_state.dart';
import 'search_models.dart';

Map<String, dynamic> _schema()=> {
  'fields':{
    'type':{'kind':'enum','values':['idea','action']},
    'status':{'kind':'enum','values':['normal','completed','archived']},
    'id':{'kind':'text'},
    'content':{'kind':'text'},
    'note':{'kind':'text'},
  },
  'computed':{'hasLinks':{'kind':'enum','values':['true','false']}},
};

enum ImportKind{ query, data, unknown }

ImportKind detectJsonType(String jsonStr){
  try{
    final j=jsonDecode(jsonStr) as Map<String,dynamic>;
    final t=j['type'];
    if(t=='query') return ImportKind.query;
    if(t=='data') return ImportKind.data;
    return ImportKind.unknown;
  }catch(_){ return ImportKind.unknown; }
}

// ---- Query
String exportQueryJson(SearchSpec spec)=> jsonEncode({
  'version':1,'schema':_schema(),'type':'query','query':spec.toJson()
});
SearchSpec importQueryJson(String jsonStr){
  final j=jsonDecode(jsonStr) as Map<String,dynamic>;
  if(j['type']!='query') throw Exception('No es JSON de búsqueda');
  return SearchSpec.fromJson((j['query'] as Map).cast<String,dynamic>());
}

// ---- Data (export siempre disponible; import = reemplazo simple)
String exportDataJson(AppState st){
  final items = st.all.map((it)=> {
    'id': it.id,
    'type': switch(it.type){ ItemType.idea=>'idea', ItemType.action=>'action' },
    'status': switch(it.status){ ItemStatus.normal=>'normal', ItemStatus.completed=>'completed', ItemStatus.archived=>'archived' },
    'content': it.text,
    'note': st.note(it.id),
    'createdAt': it.createdAt.toIso8601String(),
    'modifiedAt': it.modifiedAt.toIso8601String(),
    'statusChanges': it.statusChanges,
    'links': st.links(it.id).toList(),
  }).toList();

  return jsonEncode({
    'version':1,'schema':_schema(),'type':'data',
    'data':{
      'counters': {'idea':0,'action':0}, // opcional
      'items': items,
    }
  });
}

// Reemplaza todo por lo importado (IDs y enlaces incluidos)
void importDataJsonReplace(AppState st, String jsonStr){
  final j=jsonDecode(jsonStr) as Map<String,dynamic>;
  if(j['type']!='data') { throw Exception('No es JSON de datos'); }
  final data = (j['data'] as Map).cast<String,dynamic>();
  final itemsRaw = (data['items'] as List).cast<Map>();

  final items=<Item>[];
  final notes=<String,String>{};
  final links=<String,Set<String>>{};
  for(final r in itemsRaw){
    final m=r.cast<String,dynamic>();
    final type = m['type']=='idea'? ItemType.idea : ItemType.action;
    final status = switch(m['status']){
      'completed'=>ItemStatus.completed,
      'archived'=>ItemStatus.archived,
      _=>ItemStatus.normal,
    };
    final created = DateTime.tryParse(m['createdAt']??'') ?? DateTime.now();
    final modified= DateTime.tryParse(m['modifiedAt']??'') ?? created;
    final sc = (m['statusChanges'] as num?)?.toInt() ?? 0;
    final it = Item(m['id'] as String, m['content'] as String, type, status, created, modified, sc);
    items.add(it);

    if((m['note'] as String?)?.isNotEmpty??false){ notes[it.id]=m['note']; }
    final l = (m['links'] as List? ?? const []).cast<String>();
    if(l.isNotEmpty){ links[it.id]=l.toSet(); }
  }

  // reconstruye bidireccionalidad de links
  final fixed=<String,Set<String>>{};
  for(final e in links.entries){
    fixed.putIfAbsent(e.key, ()=> <String>{}).addAll(e.value);
    for(final other in e.value){
      fixed.putIfAbsent(other, ()=> <String>{}).add(e.key);
    }
  }
  st.replaceAll(items: items, counters: {ItemType.idea:0, ItemType.action:0}, notes: notes, links: fixed);
}
