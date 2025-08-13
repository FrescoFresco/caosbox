import 'package:caosbox/core/utils/tri.dart';

/// ------------------------------------------------------------------
/// MODELOS DE BÚSQUEDA (modulares)
/// ------------------------------------------------------------------

/// Cómo comparar texto
enum TextMatch { contains, prefix, exact }

/// Token con modo tri (include/exclude/off)
class Token {
  final String t;
  final Tri mode;
  const Token(this.t, this.mode);

  Token clone() => Token(t, mode);
}

/// Cláusula base
abstract class Clause {
  const Clause();
  Clause clone();
}

/// Campos discretos (enum): p.ej. 'type', 'status'
class EnumClause extends Clause {
  final String field;           // 'type' | 'status'
  final Set<String> include;    // valores a incluir
  final Set<String> exclude;    // valores a excluir

  const EnumClause({
    required this.field,
    this.include = const {},
    this.exclude = const {},
  });

  @override
  EnumClause clone() => EnumClause(
        field: field,
        include: {...include},
        exclude: {...exclude},
      );
}

/// Texto multicapas (id/content/note) con tokens tri y modo de coincidencia
class TextClause extends Clause {
  final Map<String, Tri> fields;    // 'id' | 'content' | 'note' -> Tri
  final List<Token> tokens;         // tokens include/exclude
  final TextMatch match;            // contains/prefix/exact

  const TextClause({
    required this.fields,
    required this.tokens,
    this.match = TextMatch.contains,
  });

  @override
  TextClause clone() => TextClause(
        fields: Map<String, Tri>.from(fields),
        tokens: [for (final t in tokens) t.clone()],
        match: match,
      );
}

/// Booleanos (sí/no): p.ej. 'hasLinks'
class BoolClause extends Clause {
  final String field;   // 'hasLinks'
  final Tri mode;       // include => true, exclude => false, off => ignora

  const BoolClause({required this.field, required this.mode});

  @override
  BoolClause clone() => BoolClause(field: field, mode: mode);
}

/// Relación con otro ítem por id (grafo)
class RelationClause extends Clause {
  final String anchorId;
  final Tri mode; // include => relacionado; exclude => NO relacionado

  const RelationClause({required this.anchorId, required this.mode});

  @override
  RelationClause clone() => RelationClause(anchorId: anchorId, mode: mode);
}

/// Conjunto de cláusulas
class SearchSpec {
  final List<Clause> clauses;
  const SearchSpec({this.clauses = const []});

  SearchSpec clone() => SearchSpec(clauses: [for (final c in clauses) c.clone()]);
}
