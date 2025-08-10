import '../models/item.dart';
import '../models/enums.dart';
import '../state/app_state.dart';
import 'search_models.dart';

String _norm(String s) => s.toLowerCase();
bool _has(String text, String tok) => _norm(text).contains(_norm(tok));
bool _pass(Tri mode, bool v) => switch (mode) { Tri.off => true, Tri.include => v, Tri.exclude => !v };

bool _matchText(Item it, AppState st, TextClause c) {
  final id = it.id, content = it.text, note = st.note(it.id);
  final includes = c.fields.entries.where((e) => e.value == Tri.include).map((e) => e.key).toSet();
  final excludes = c.fields.entries.where((e) => e.value == Tri.exclude).map((e) => e.key).toSet();

  bool consider(String f) => includes.isNotEmpty ? includes.contains(f) : !excludes.contains(f);
  bool inAny(String tok) {
    if (consider('id') && _has(id, tok)) return true;
    if (consider('content') && _has(content, tok)) return true;
    if (consider('note') && _has(note, tok)) return true;
    return false;
  }

  // Excluyentes primero
  for (final t in c.tokens.where((t) => t.mode == Tri.exclude)) {
    final tok = t.t.trim();
    if (tok.isNotEmpty && inAny(tok)) return false;
  }
  // Inclusivos: deben cumplirse todos
  for (final t in c.tokens.where((t) => t.mode != Tri.exclude)) {
    final tok = t.t.trim();
    if (tok.isNotEmpty && !inAny(tok)) return false;
  }
  return true;
}

List<Item> applySearch(AppState st, List<Item> source, SearchSpec spec) {
  Iterable<Item> items = source;

  // 1) Filtrado por cláusulas
  for (final clause in spec.clauses) {
    if (clause is EnumClause) {
      final inc = clause.include, exc = clause.exclude;
      items = items.where((it) {
        switch (clause.field) {
          case 'type':
            final v = switch (it.type) { ItemType.idea => 'idea', ItemType.action => 'action' };
            return inc.isNotEmpty ? inc.contains(v) : !exc.contains(v);
          case 'status':
            final v = switch (it.status) {
              ItemStatus.normal => 'normal',
              ItemStatus.completed => 'completed',
              ItemStatus.archived => 'archived',
            };
            return inc.isNotEmpty ? inc.contains(v) : !exc.contains(v);
          case 'hasLinks':
            final has = st.links(it.id).isNotEmpty;
            final m = inc.contains('true') ? Tri.include : (inc.isEmpty && exc.contains('true') ? Tri.exclude : Tri.off);
            return _pass(m, has);
          default:
            return true;
        }
      });
    } else if (clause is TextClause) {
      items = items.where((it) => _matchText(it, st, clause));
    }
  }

  final L = items.toList();

  // 2) Orden: si NO hay cláusulas de texto → modifiedAt desc
  final textClauses = spec.clauses.whereType<TextClause>().toList();
  if (textClauses.isEmpty) {
    L.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return L;
  }

  // Si hay texto, sumar score de TODAS las TextClause
  int score(Item it) {
    int s = 0;
    for (final tc in textClauses) {
      for (final t in tc.tokens.where((t) => t.mode == Tri.include)) {
        final tok = t.t;
        if (_has(it.text, tok)) s += 4;
        if (_has(st.note(it.id), tok)) s += 2;
        if (_has(it.id, tok)) s += 1;
      }
    }
    return s;
  }

  L.sort((a, b) {
    final sa = score(a), sb = score(b);
    if (sa != sb) return sb.compareTo(sa); // mayor score primero
    return b.modifiedAt.compareTo(a.modifiedAt); // empate: más reciente primero
  });
  return L;
}
