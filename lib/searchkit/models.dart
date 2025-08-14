import 'package:caosbox/core/utils/tri.dart';

enum TextMatch { contains, prefix, exact }

class Token {
  final String t;
  final Tri mode; // include | exclude | off
  const Token(this.t, this.mode);
  Token clone() => Token(t, mode);
}

abstract class Clause {
  const Clause();
  Clause clone();
}

/// Bloque de TEXTO: element ∈ { id, content, note }
class TextClause extends Clause {
  final String element; // 'id' | 'content' | 'note'
  final Tri presence;   // include => debe tener; exclude => NO debe tener; off => ignorar
  final List<Token> tokens;
  final TextMatch match;

  const TextClause({
    required this.element,
    this.presence = Tri.off,
    this.tokens = const [],
    this.match = TextMatch.contains,
  });

  @override
  TextClause clone() => TextClause(
        element: element,
        presence: presence,
        tokens: [for (final t in tokens) t.clone()],
        match: match,
      );
}

/// Bloque de BANDERA/ENUM/RELACIÓN:
/// field: 'type' | 'status' (usa include/exclude)
/// field: 'hasLinks' (usa mode)
/// field: 'relation' (usa mode + anchorId)
class FlagClause extends Clause {
  final String field;
  final Set<String> include;
  final Set<String> exclude;
  final Tri mode;
  final String? anchorId;

  const FlagClause({
    required this.field,
    this.include = const {},
    this.exclude = const {},
    this.mode = Tri.off,
    this.anchorId,
  });

  @override
  FlagClause clone() => FlagClause(
        field: field,
        include: {...include},
        exclude: {...exclude},
        mode: mode,
        anchorId: anchorId,
      );
}

enum Op { and, or }

abstract class QueryNode {
  const QueryNode();
  QueryNode clone();
}

class LeafNode extends QueryNode {
  final Clause clause;
  final String? label;
  const LeafNode({required this.clause, this.label});
  @override
  LeafNode clone() => LeafNode(clause: clause.clone(), label: label);
}

class GroupNode extends QueryNode {
  final Op op;
  final List<QueryNode> children;
  final String? label;
  const GroupNode({required this.op, required this.children, this.label});
  @override
  GroupNode clone() => GroupNode(
        op: op,
        children: [for (final c in children) c.clone()],
        label: label,
      );
}

class SearchSpec {
  final GroupNode root; // árbol mínimo
  const SearchSpec({required this.root});
  SearchSpec clone() => SearchSpec(root: root.clone() as GroupNode);
}
