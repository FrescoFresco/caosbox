import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/core/models/item.dart';
import 'package:caosbox/core/models/enums.dart';
import 'package:caosbox/core/utils/tri.dart';

import 'package:caosbox/domain/search/search_models.dart';

Iterable<Item> applySearch(AppState st, List<Item> src, SearchSpec spec) sync* {
  for (final it in src) {
    if (_matchAll(st, it, spec)) yield it;
  }
}

bool _matchAll(AppState st, Item it, SearchSpec spec) {
  for (final c in spec.clauses) {
    if (c is EnumClause) {
      if (!_matchEnum(it, c)) return false;
    } else if (c is BoolClause) {
      if (!_matchBool(st, it, c)) return false;
    } else if (c is RelationClause) {
      if (!_matchRelation(st, it, c)) return false;
    } else if (c is TextClause) {
      if (!_matchText(st, it, c)) return false;
    }
  }
  return true;
}

bool _matchEnum(Item it, EnumClause c) {
  String value = '';
  switch (c.field) {
    case 'type':
      value = it.type.name; // 'idea' | 'action'
      break;
    case 'status':
      value = it.status.name.toLowerCase(); // 'normal' | 'completed' | 'archived'
      break;
    default:
      return true; // campo desconocido => no filtra
  }

  if (c.include.isNotEmpty && !c.include.contains(value)) return false;
  if (c.exclude.contains(value)) return false;
  return true;
}

bool _matchBool(AppState st, Item it, BoolClause c) {
  if (c.mode == Tri.off) return true;
  switch (c.field) {
    case 'hasLinks':
      final has = st.links(it.id).isNotEmpty;
      return c.mode == Tri.include ? has : !has;
  }
  return true;
}

bool _matchRelation(AppState st, Item it, RelationClause c) {
  if (c.mode == Tri.off) return true;
  // Evita autovínculo
  if (c.anchorId == it.id) {
    return c.mode == Tri.exclude; // "incluir relacionado con sí mismo" => falso
  }
  final related = st.links(c.anchorId).contains(it.id);
  return c.mode == Tri.include ? related : !related;
}

bool _matchText(AppState st, Item it, TextClause c) {
  // Determina en qué campos mirar
  final useId     = (c.fields['id'] ?? Tri.off)     != Tri.off;
  final useText   = (c.fields['content'] ?? Tri.off)!= Tri.off;
  final useNote   = (c.fields['note'] ?? Tri.off)   != Tri.off;

  if (!useId && !useText && !useNote) return true;

  final id    = it.id.toLowerCase();
  final body  = it.text.toLowerCase();
  final note  = st.note(it.id).toLowerCase();

  bool contains(String hay, String needle) {
    if (needle.isEmpty) return true;
    return hay.contains(needle);
  }
  bool prefix(String hay, String needle) {
    if (needle.isEmpty) return true;
    return hay.startsWith(needle);
  }
  bool exact(String hay, String needle) => hay == needle;

  bool Function(String, String) cmp;
  switch (c.match) {
    case TextMatch.prefix:   cmp = prefix;   break;
    case TextMatch.exact:    cmp = exact;    break;
    case TextMatch.contains: cmp = contains; break;
  }

  for (final tok in c.tokens) {
    final q = tok.t.toLowerCase();
    final hit = ((useId   && cmp(id, q)) ||
                 (useText && cmp(body, q)) ||
                 (useNote && cmp(note, q)));
    if (tok.mode == Tri.include && !hit) return false;
    if (tok.mode == Tri.exclude &&  hit) return false;
  }
  return true;
}
