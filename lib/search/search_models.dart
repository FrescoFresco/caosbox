enum Tri { off, include, exclude }
enum ClauseKind { enumKind, text }

abstract class Clause {
  ClauseKind get kind;
  Map<String, dynamic> toJson();
}

class EnumClause implements Clause {
  final String field;
  final Set<String> include;
  final Set<String> exclude;
  EnumClause({required this.field, Set<String>? include, Set<String>? exclude})
      : include = include ?? <String>{}, exclude = exclude ?? <String>{};
  @override ClauseKind get kind => ClauseKind.enumKind;
  @override Map<String, dynamic> toJson() => {
    'kind':'enum','field':field,'include':include.toList(),'exclude':exclude.toList()
  };
  factory EnumClause.fromJson(Map<String, dynamic> j) => EnumClause(
    field: j['field'] as String,
    include: (j['include'] as List? ?? const []).cast<String>().toSet(),
    exclude: (j['exclude'] as List? ?? const []).cast<String>().toSet(),
  );
}

class Token {
  final String t; final Tri mode;
  const Token(this.t, this.mode);
  Map<String, dynamic> toJson()=>{'t':t,'mode':switch(mode){Tri.include=>'include',Tri.exclude=>'exclude',_=>'off'}};
  factory Token.fromJson(Map<String,dynamic> j)=>Token(j['t'] as String, switch(j['mode']){'include'=>Tri.include,'exclude'=>Tri.exclude,_=>Tri.off});
}

class TextClause implements Clause {
  final Map<String, Tri> fields;
  final List<Token> tokens;
  TextClause({Map<String,Tri>? fields, List<Token>? tokens})
    : fields = fields ?? {'id':Tri.off,'content':Tri.include,'note':Tri.include},
      tokens = tokens ?? [];
  @override ClauseKind get kind => ClauseKind.text;
  @override Map<String,dynamic> toJson()=> {
    'kind':'text',
    'fields': fields.map((k,v)=> MapEntry(k, switch(v){Tri.include=>'include',Tri.exclude=>'exclude',_=>'off'})),
    'tokens': tokens.map((e)=>e.toJson()).toList(),
  };
  factory TextClause.fromJson(Map<String,dynamic> j){
    final raw = (j['fields'] as Map).cast<String,dynamic>();
    final m = <String,Tri>{};
    raw.forEach((k,v){ m[k]=switch(v){'include'=>Tri.include,'exclude'=>Tri.exclude,_=>Tri.off}; });
    final toks = (j['tokens'] as List? ?? const []).map((e)=>Token.fromJson((e as Map).cast<String,dynamic>())).toList();
    return TextClause(fields:m, tokens:toks);
  }
}

class SearchSpec {
  final List<Clause> clauses;
  const SearchSpec({this.clauses=const []});
  Map<String,dynamic> toJson()=>{'logic':'AND','clauses':clauses.map((c)=>c.toJson()).toList()};
  factory SearchSpec.fromJson(Map<String,dynamic> j){
    final out=<Clause>[];
    for(final raw in (j['clauses'] as List? ?? const [])){
      final m=(raw as Map).cast<String,dynamic>();
      switch(m['kind']){
        case 'enum': out.add(EnumClause.fromJson(m)); break;
        case 'text': out.add(TextClause.fromJson(m)); break;
      }
    }
    return SearchSpec(clauses: out);
  }
}
