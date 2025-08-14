import 'dart:convert';
import 'package:caosbox/core/utils/tri.dart';
import 'package:caosbox/searchkit/models.dart';

String exportQueryJson(SearchSpec s) {
  Map<String, dynamic> clauseToMap(Clause c) {
    if (c is TextClause) {
      return {
        'type': 'text',
        'element': c.element,
        'presence': c.presence.name, // include|exclude|off
        'tokens': [for (final t in c.tokens) {'t': t.t, 'mode': t.mode.name}],
        'match': switch (c.match) {
          TextMatch.prefix => 'prefix',
          TextMatch.exact => 'exact',
          _ => 'contains',
        },
      };
    } else if (c is FlagClause) {
      final m = <String, dynamic>{'type': 'flag', 'field': c.field};
      if (c.field == 'type' || c.field == 'status') {
        m['include'] = c.include.toList();
        m['exclude'] = c.exclude.toList();
      } else if (c.field == 'hasLinks') {
        m['mode'] = c.mode.name;
      } else if (c.field == 'relation') {
        m['mode'] = c.mode.name;
        m['anchorId'] = c.anchorId ?? '';
      }
      return m;
    }
    return {};
  }

  Map<String, dynamic> nodeToMap(QueryNode n) {
    if (n is LeafNode) {
      return {'clause': clauseToMap(n.clause), if (n.label != null) 'label': n.label};
    }
    if (n is GroupNode) {
      return {
        'op': n.op == Op.and ? 'AND' : 'OR',
        'children': [for (final c in n.children) nodeToMap(c)],
        if (n.label != null) 'label': n.label,
      };
    }
    return {};
  }

  final obj = {
    'kind': 'caosbox-query',
    'version': 3,
    'root': nodeToMap(s.root),
  };
  return const JsonEncoder.withIndent('  ').convert(obj);
}

SearchSpec importQueryJson(String text) {
  final m = json.decode(text);
  if (m is! Map || m['kind'] != 'caosbox-query') {
    throw 'Documento inválido (kind != caosbox-query)';
  }
  final v = (m['version'] ?? 2) as int;
  if (v == 3) {
    return SearchSpec(root: _mapToNode(m['root']) as GroupNode);
  }
  // Migración v2 (lista lineal) -> v3 (AND root con hojas)
  final clauses = (m['clauses'] as List? ?? []).map(_mapToClause).toList();
  final children = [for (final c in clauses) LeafNode(clause: c)];
  return SearchSpec(root: GroupNode(op: Op.and, children: children));
}

QueryNode _mapToNode(dynamic n) {
  if (n is Map && n.containsKey('clause')) {
    return LeafNode(
      clause: _mapToClause(n['clause']),
      label: n['label'] is String ? n['label'] : null,
    );
  }
  if (n is Map) {
    final op = (n['op'] == 'OR') ? Op.or : Op.and;
    final kids = <QueryNode>[
      for (final c in (n['children'] as List? ?? [])) _mapToNode(c),
    ];
    return GroupNode(op: op, children: kids, label: n['label'] is String ? n['label'] : null);
  }
  return GroupNode(op: Op.and, children: const []);
}

Clause _mapToClause(dynamic c) {
  if (c is! Map) return const FlagClause(field: 'type');
  final type = '${c['type']}';
  if (type == 'text') {
    return TextClause(
      element: '${c['element'] ?? 'content'}',
      presence: switch ('${c['presence'] ?? 'off'}') {
        'include' => Tri.include,
        'exclude' => Tri.exclude,
        _ => Tri.off
      },
      tokens: [
        for (final t in (c['tokens'] as List? ?? []))
          Token('${t['t']}', switch ('${t['mode']}') {
            'exclude' => Tri.exclude,
            'include' => Tri.include,
            _ => Tri.off
          })
      ],
      match: switch ('${c['match'] ?? 'contains'}') {
        'prefix' => TextMatch.prefix,
        'exact' => TextMatch.exact,
        _ => TextMatch.contains
      },
    );
  } else {
    final field = '${c['field'] ?? 'type'}';
    if (field == 'type' || field == 'status') {
      return FlagClause(
        field: field,
        include: {...(c['include'] as List? ?? []).map((e) => '$e')},
        exclude: {...(c['exclude'] as List? ?? []).map((e) => '$e')},
      );
    } else if (field == 'hasLinks') {
      return FlagClause(field: field, mode: switch ('${c['mode']}') {
        'include' => Tri.include,
        'exclude' => Tri.exclude,
        _ => Tri.off
      });
    } else {
      return FlagClause(
        field: 'relation',
        mode: switch ('${c['mode']}') {
          'include' => Tri.include,
          'exclude' => Tri.exclude,
          _ => Tri.off
        },
        anchorId: c['anchorId'] != null ? '${c['anchorId']}' : null,
      );
    }
  }
}
