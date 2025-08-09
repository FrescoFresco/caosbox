// Modelo de la búsqueda por bloques (enum/text) con tri-estado y JSON.

enum Tri { off, include, exclude }

enum ClauseKind { enumKind, text }

abstract class Clause {
  ClauseKind get kind;
  Map<String, dynamic> toJson();
}

class EnumClause implements Clause {
  // field: 'type' | 'status' | 'hasLinks' (derivado)
  final String field;
  final Set<String> include;
  final Set<String> exclude;

  EnumClause({required this.field, Set<String>? include, Set<String>? exclude})
      : include = include ?? <String>{},
        exclude = exclude ?? <String>{};

  @override
  ClauseKind get kind => ClauseKind.enumKind;

  @override
  Map<String, dynamic> toJson() => {
        'kind': 'enum',
        'field': field,
        'include': include.toList(),
        'exclude': exclude.toList(),
      };

  factory EnumClause.fromJson(Map<String, dynamic> j) => EnumClause(
        field: j['field'] as String,
        include: (j['include'] as List? ?? const []).cast<String>().toSet(),
        exclude: (j['exclude'] as List? ?? const []).cast<String>().toSet(),
      );
}

class Token {
  final String t; // token (minúsculas recomendado)
  final Tri mode; // include / exclude

  const Token(this.t, this.mode);

  Map<String, dynamic> toJson() => {
        't': t,
        'mode': switch (mode) {
          Tri.off => 'off',
          Tri.include => 'include',
          Tri.exclude => 'exclude',
        },
      };

  factory Token.fromJson(Map<String, dynamic> j) => Token(
        j['t'] as String,
        switch (j['mode']) {
          'include' => Tri.include,
          'exclude' => Tri.exclude,
          _ => Tri.off,
        },
      );
}

class TextClause implements Clause {
  // fields: tri-estado por campo: id / content / note
  // p.ej. {'id':'off','content':'include','note':'include'}
  final Map<String, Tri> fields;
  final List<Token> tokens;

  TextClause({Map<String, Tri>? fields, List<Token>? tokens})
      : fields = fields ?? const {'id': Tri.off, 'content': Tri.include, 'note': Tri.include},
        tokens = tokens ?? const [];

  @override
  ClauseKind get kind => ClauseKind.text;

  @override
  Map<String, dynamic> toJson() => {
        'kind': 'text',
        'fields': fields.map((k, v) => MapEntry(k, switch (v) {
              Tri.off => 'off',
              Tri.include => 'include',
              Tri.exclude => 'exclude',
            })),
        'tokens': tokens.map((e) => e.toJson()).toList(),
      };

  factory TextClause.fromJson(Map<String, dynamic> j) {
    final raw = (j['fields'] as Map).cast<String, dynamic>();
    final mapTri = <String, Tri>{};
    for (final e in raw.entries) {
      mapTri[e.key] = switch (e.value) {
        'include' => Tri.include,
        'exclude' => Tri.exclude,
        _ => Tri.off,
      };
    }
    final toks = (j['tokens'] as List? ?? const [])
        .map((e) => Token.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    return TextClause(fields: mapTri, tokens: toks);
  }
}

class SearchSpec {
  final List<Clause> clauses;
  const SearchSpec({this.clauses = const []});

  Map<String, dynamic> toJson() => {
        'logic': 'AND',
        'clauses': clauses.map((c) => c.toJson()).toList(),
      };

  factory SearchSpec.fromJson(Map<String, dynamic> j) {
    final list = <Clause>[];
    for (final raw in (j['clauses'] as List? ?? const [])) {
      final m = (raw as Map).cast<String, dynamic>();
      switch (m['kind']) {
        case 'enum':
          list.add(EnumClause.fromJson(m));
          break;
        case 'text':
          list.add(TextClause.fromJson(m));
          break;
      }
    }
    return SearchSpec(clauses: list);
  }
}
