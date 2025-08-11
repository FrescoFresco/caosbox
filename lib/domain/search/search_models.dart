import 'package:caosbox/core/utils/tri.dart';

abstract class Clause { Clause clone(); }

class EnumClause extends Clause {
  final String field; // 'type' | 'status' | 'hasLinks'
  final Set<String> include;
  final Set<String> exclude;

  EnumClause({required this.field, Set<String>? include, Set<String>? exclude})
      : include = include ?? <String>{},
        exclude = exclude ?? <String>{};

  @override
  EnumClause clone() => EnumClause(field: field, include: {...include}, exclude: {...exclude});
}

class Token {
  final String t;
  final Tri mode; // include / exclude
  const Token(this.t, this.mode);
}

class TextClause extends Clause {
  // fields: id/content/note → Tri
  final Map<String, Tri> fields;
  final List<Token> tokens;

  TextClause({Map<String, Tri>? fields, List<Token>? tokens})
      : fields = fields ?? <String, Tri>{},
        tokens = tokens ?? <Token>[];

  @override
  TextClause clone() => TextClause(fields: {...fields}, tokens: [...tokens]);
}

class SearchSpec {
  final List<Clause> clauses;
  const SearchSpec({this.clauses = const []});
  SearchSpec clone() => SearchSpec(clauses: clauses.map((c) => c.clone()).toList());
}
