import 'package:caosbox/core/models/item.dart';
import 'package:caosbox/core/models/enums.dart';
import 'package:caosbox/core/utils/tri.dart';
import 'package:caosbox/domain/search/search_models.dart';
import 'package:caosbox/app/state/app_state.dart';

List<Item> applySearch(AppState st, List<Item> items, SearchSpec spec) {
  if (spec.clauses.isEmpty) return items;

  bool passEnum(EnumClause c, Item it) {
    bool test(String v) {
      if (c.include.isNotEmpty && !c.include.contains(v)) return false;
      if (c.exclude.isNotEmpty && c.exclude.contains(v)) return false;
      return true;
    }
    switch (c.field) {
      case 'type':   return test(it.type.name);
      case 'status': return test(it.status.name);
      case 'hasLinks': return test(st.links(it.id).isNotEmpty ? 'true' : 'false');
      default: return true;
    }
  }

  bool passText(TextClause tc, Item it) {
    // Alcance
    final fields = tc.fields.entries.where((e) => e.value != Tri.off).map((e) => e.key).toSet();
    final searchAll = fields.isEmpty;
    final id = it.id.toLowerCase();
    final content = it.text.toLowerCase();
    final note = (st.note(it.id)).toLowerCase();

    bool containsToken(String tok) {
      if (searchAll || fields.contains('id')) if (id.contains(tok)) return true;
      if (searchAll || fields.contains('content')) if (content.contains(tok)) return true;
      if (searchAll || fields.contains('note')) if (note.contains(tok)) return true;
      return false;
    }

    // Includes: todos deben aparecer en alguno de los campos del alcance
    for (final t in tc.tokens.where((t) => t.mode == Tri.include)) {
      if (t.t.isEmpty) continue;
      if (!containsToken(t.t.toLowerCase())) return false;
    }
    // Excludes: ninguno debe aparecer
    for (final t in tc.tokens.where((t) => t.mode == Tri.exclude)) {
      if (t.t.isEmpty) continue;
      if (containsToken(t.t.toLowerCase())) return false;
    }
    return true;
  }

  bool passAll(Item it) {
    for (final c in spec.clauses) {
      if (c is EnumClause) { if (!passEnum(c, it)) return false; }
      if (c is TextClause) { if (!passText(c, it)) return false; }
    }
    return true;
  }

  return items.where(passAll).toList(growable: false);
}
