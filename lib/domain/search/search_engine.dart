import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/core/models/item.dart';
import 'package:caosbox/core/models/enums.dart';
import 'package:caosbox/core/utils/tri.dart';

import 'package:caosbox/domain/search/search_models.dart';

Iterable<Item> applySearch(AppState st, Iterable<Item> src, SearchSpec spec) sync* {
  for (final it in src) {
    if (_evalNode(st, it, spec.root)) yield it;
  }
}

bool _evalNode(AppState st, Item it, QueryNode n) {
  if (n is LeafNode) return _evalClause(st, it, n.clause);
  if (n is GroupNode) {
    if (n.children.isEmpty) return true;
    bool acc = _evalNode(st, it, n.children.first);
    for (int i = 1; i < n.children.length; i++) {
      final cur = _evalNode(st, it, n.children[i]);
      if (n.op == Op.and) {
        acc = acc && cur;
        if (!acc) return false; // short-circuit
      } else {
        acc = acc || cur;
        if (acc) return true;   // short-circuit
      }
    }
    return acc;
  }
  return true;
}

bool _evalClause(AppState st, Item it, Clause c) {
  if (c is TextClause) return _matchText(st, it, c);
  if (c is FlagClause) return _matchFlag(st, it, c);
  return true;
}

bool _matchText(AppState st, Item it, TextClause c) {
  String source;
  switch (c.element) {
    case 'id':
      source = it.id;
      break;
    case 'note':
      source = st.note(it.id);
      break;
    default:
      source = it.text; // 'content'
  }
  final s = source.toLowerCase();

  // presence
  if (c.presence != Tri.off) {
    final has = s.trim().isNotEmpty;
    if (c.presence == Tri.include && !has) return false;
    if (c.presence == Tri.exclude && has)  return false;
  }

  bool contains(String hay, String needle) => needle.isEmpty || hay.contains(needle);
  bool prefix(String hay, String needle)   => needle.isEmpty || hay.startsWith(needle);
  bool exact(String hay, String needle)    => hay == needle;

  bool Function(String, String) cmp;
  switch (c.match) {
    case TextMatch.prefix:   cmp = prefix;   break;
    case TextMatch.exact:    cmp = exact;    break;
    case TextMatch.contains: cmp = contains; break;
  }

  for (final t in c.tokens) {
    final q = t.t.toLowerCase();
    final hit = cmp(s, q);
    if (t.mode == Tri.include && !hit) return false;
    if (t.mode == Tri.exclude &&  hit) return false;
  }
  return true;
}

bool _matchFlag(AppState st, Item it, FlagClause c) {
  switch (c.field) {
    case 'type': {
      final v = it.type.name; // 'idea' | 'action'
      if (c.include.isNotEmpty && !c.include.contains(v)) return false;
      if (c.exclude.contains(v)) return false;
      return true;
    }
    case 'status': {
      final v = it.status.name.toLowerCase(); // 'normal'|'completed'|'archived'
      if (c.include.isNotEmpty && !c.include.contains(v)) return false;
      if (c.exclude.contains(v)) return false;
      return true;
    }
    case 'hasLinks': {
      if (c.mode == Tri.off) return true;
      final has = st.links(it.id).isNotEmpty;
      return c.mode == Tri.include ? has : !has;
    }
    case 'relation': {
      if (c.mode == Tri.off) return true;
      final anchor = (c.anchorId ?? '').trim();
      if (anchor.isEmpty) return true;
      final isRelated = st.links(anchor).contains(it.id);
      return c.mode == Tri.include ? isRelated : !isRelated;
    }
  }
  return true;
}
