// Motor que aplica SearchSpec sobre tus Items + AppState (para note/links).

import '../models/item.dart';
import '../models/enums.dart';
import '../state/app_state.dart';
import 'search_models.dart';

bool _pass(Tri mode, bool value) => switch (mode) {
      Tri.off => true,
      Tri.include => value,
      Tri.exclude => !value,
    };

String _norm(String s) => s.toLowerCase(); // se puede mejorar (quitar acentos)

bool _fieldHas(String text, String tok) => _norm(text).contains(_norm(tok));

bool _matchText(Item it, AppState st, TextClause c) {
  final id = it.id;
  final content = it.text;
  final note = st.note(it.id);

  // Qué campos considerar
  final includes = c.fields.entries.where((e) => e.value == Tri.include).map((e) => e.key).toSet();
  final excludes = c.fields.entries.where((e) => e.value == Tri.exclude).map((e) => e.key).toSet();

  bool consider(String f) {
    if (includes.isNotEmpty) return includes.contains(f);
    return !excludes.contains(f);
  }

  bool containsInAny(String tok) {
    if (consider('id') && _fieldHas(id, tok)) return true;
    if (consider('content') && _fieldHas(content, tok)) return true;
    if (consider('note') && _fieldHas(note, tok)) return true;
    return false;
  }

  // Tokens negativos descartan si aparecen en campos considerados
  for (final t in c.tokens.where((t) => t.mode == Tri.exclude)) {
    if (t.t.trim().isEmpty) continue;
    if (containsInAny(t.t)) return false;
  }

  // Tokens positivos: todos deben aparecer (en al menos un campo considerado)
  for (final t in c.tokens.where((t) => t.mode != Tri.exclude)) {
    if (t.t.trim().isEmpty) continue; // off o vacío
    if (!containsInAny(t.t)) return false;
  }
  return true;
}

List<Item> applySearch(AppState st, List<Item> source, SearchSpec spec) {
  Iterable<Item> items = source;

  for (final clause in spec.clauses) {
    if (clause is EnumClause) {
      final inc = clause.include;
      final exc = clause.exclude;

      bool ok(Item it) {
        switch (clause.field) {
          case 'type':
            final v = switch (it.type) { ItemType.idea => 'idea', ItemType.action => 'action' };
            if (inc.isNotEmpty) return inc.contains(v);
            return !exc.contains(v);

          case 'status':
            final v = switch (it.status) {
              ItemStatus.normal => 'normal',
              ItemStatus.completed => 'completed',
              ItemStatus.archived => 'archived',
            };
            if (inc.isNotEmpty) return inc.contains(v);
            return !exc.contains(v);

          case 'hasLinks':
            final has = st.links(it.id).isNotEmpty;
            final m = inc.contains('true')
                ? Tri.include
                : (inc.isEmpty && exc.contains('true') ? Tri.exclude : Tri.off);
            return _pass(m, has);

          default:
            return true; // campo desconocido → no filtra
        }
      }

      items = items.where(ok);
    } else if (clause is TextClause) {
      items = items.where((it) => _matchText(it, st, clause));
    }
  }

  // Ranking sencillo: contenido > nota > id ; empate por modifiedAt
  int score(Item it, TextClause? tc) {
    if (tc == null) return 0;
    int s = 0;
    for (final t in tc.tokens.where((t) => t.mode == Tri.include)) {
      if (_fieldHas(it.text, t.t)) s += 4;
      if (_fieldHas(st.note(it.id), t.t)) s += 2;
      if (_fieldHas(it.id, t.t)) s += 1;
    }
    return s;
  }

  final firstText = spec.clauses.whereType<TextClause>().firstOrNull;
  final list = items.toList();
  list.sort((a, b) {
    final sa = score(a, firstText);
    final sb = score(b, firstText);
    if (sa != sb) return sb.compareTo(sa);
    return b.modifiedAt.compareTo(a.modifiedAt);
  });
  return list;
}

// Extensión útil para null-safety
extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
