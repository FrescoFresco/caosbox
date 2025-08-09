import '../models/item.dart';
import '../models/enums.dart';
import '../state/app_state.dart';
import 'search_models.dart';

String _norm(String s)=> s.toLowerCase();
bool _has(String text, String tok)=> _norm(text).contains(_norm(tok));

bool _pass(Tri mode, bool v)=> switch(mode){Tri.off=>true,Tri.include=>v,Tri.exclude=>!v};

bool _matchText(Item it, AppState st, TextClause c){
  final id=it.id, content=it.text, note=st.note(it.id);
  final includes = c.fields.entries.where((e)=>e.value==Tri.include).map((e)=>e.key).toSet();
  final excludes = c.fields.entries.where((e)=>e.value==Tri.exclude).map((e)=>e.key).toSet();

  bool consider(String f){ if(includes.isNotEmpty) return includes.contains(f); return !excludes.contains(f); }
  bool inAny(String tok){
    if(consider('id') && _has(id,tok)) return true;
    if(consider('content') && _has(content,tok)) return true;
    if(consider('note') && _has(note,tok)) return true;
    return false;
  }

  // negativos descartan
  for(final t in c.tokens.where((t)=>t.mode==Tri.exclude)){
    if(t.t.trim().isEmpty) continue;
    if(inAny(t.t)) return false;
  }
  // positivos (y off tratados como positivos)
  for(final t in c.tokens.where((t)=>t.mode!=Tri.exclude)){
    if(t.t.trim().isEmpty) continue;
    if(!inAny(t.t)) return false;
  }
  return true;
}

List<Item> applySearch(AppState st, List<Item> source, SearchSpec spec){
  Iterable<Item> items = source;

  for(final clause in spec.clauses){
    if(clause is EnumClause){
      final inc=clause.include, exc=clause.exclude;
      items = items.where((it){
        switch(clause.field){
          case 'type':
            final v = switch(it.type){ ItemType.idea=>'idea', ItemType.action=>'action' };
            return inc.isNotEmpty ? inc.contains(v) : !exc.contains(v);
          case 'status':
            final v = switch(it.status){ ItemStatus.normal=>'normal', ItemStatus.completed=>'completed', ItemStatus.archived=>'archived' };
            return inc.isNotEmpty ? inc.contains(v) : !exc.contains(v);
          case 'hasLinks':
            final has = st.links(it.id).isNotEmpty;
            final m = inc.contains('true') ? Tri.include : (inc.isEmpty && exc.contains('true') ? Tri.exclude : Tri.off);
            return _pass(m, has);
          default: return true;
        }
      });
    } else if (clause is TextClause){
      items = items.where((it)=> _matchText(it, st, clause));
    }
  }

  // ranking sencillo
  int score(Item it, TextClause? tc){
    if(tc==null) return 0;
    int s=0;
    for(final t in tc.tokens.where((t)=>t.mode==Tri.include)){
      if(_has(it.text, t.t)) s+=4;
      if(_has(st.note(it.id), t.t)) s+=2;
      if(_has(it.id, t.t)) s+=1;
    }
    return s;
  }

  final firstText = spec.clauses.whereType<TextClause>().isEmpty ? null : spec.clauses.whereType<TextClause>().first;
  final L = items.toList();
  L.sort((a,b){
    final sa=score(a, firstText), sb=score(b, firstText);
    if(sa!=sb) return sb.compareTo(sa);
    return b.modifiedAt.compareTo(a.modifiedAt);
  });
  return L;
}
