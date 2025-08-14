import 'dart:convert';
import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/core/models/enums.dart';
import 'package:caosbox/core/models/item.dart';
import 'package:caosbox/core/utils/tri.dart';
import 'package:caosbox/domain/search/search_models.dart';

/// ====================== DATOS (items) ======================

String exportDataJson(AppState st) {
  final data = {
    'kind': 'caosbox-data',
    'version': 1,
    'meta': {
      'counters': {
        'idea': st.counters[ItemType.idea] ?? 0,
        'action': st.counters[ItemType.action] ?? 0,
      },
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
    },
    'items': [
      for (final it in st.all)
        {
          'id': it.id,
          'type': it.type.name,
          'status': it.status.name,
          'text': it.text,
          'createdAt': it.createdAt.toUtc().toIso8601String(),
          'modifiedAt': it.modifiedAt.toUtc().toIso8601String(),
          'statusChanges': it.statusChanges,
        }
    ],
    'notes': {
      for (final it in st.all)
        if (st.note(it.id).isNotEmpty) it.id: st.note(it.id)
    },
    'links': _linksPairs(st),
  };
  return const JsonEncoder.withIndent('  ').convert(data);
}

List<List<String>> _linksPairs(AppState st) {
  final seen = <String>{};
  final out = <List<String>>[];
  for (final it in st.all) {
    for (final b in st.links(it.id)) {
      final a = it.id;
      if (a == b) continue;
      final key = a.compareTo(b) <= 0 ? '$a|$b' : '$b|$a';
      if (seen.add(key)) {
        out.add(a.compareTo(b) <= 0 ? [a, b] : [b, a]);
      }
    }
  }
  return out;
}

void importDataJsonReplace(AppState st, String text) {
  final m = json.decode(text);
  if (m is! Map || m['kind'] != 'caosbox-data') {
    throw 'Documento inválido (kind != caosbox-data)';
  }

  final items = <Item>[];
  for (final e in (m['items'] as List? ?? [])) {
    final type = (e['type'] == 'idea') ? ItemType.idea : ItemType.action;
    final status = switch (('${e['status']}'.toLowerCase())) {
      'completed' => ItemStatus.completed,
      'archived'  => ItemStatus.archived,
      _           => ItemStatus.normal,
    };
    items.add(Item(
      e['id'],
      e['text'] ?? '',
      type,
      status: status,
      createdAt: DateTime.tryParse(e['createdAt'] ?? '') ?? DateTime.now(),
      modifiedAt: DateTime.tryParse(e['modifiedAt'] ?? '') ?? DateTime.now(),
      statusChanges: e['statusChanges'] is int ? e['statusChanges'] : 0,
    ));
  }

  final counters = {
    ItemType.idea: (m['meta']?['counters']?['idea'] ?? 0) as int,
    ItemType.action: (m['meta']?['counters']?['action'] ?? 0) as int,
  };

  final links = <String, Set<String>>{};
  for (final p in (m['links'] as List? ?? [])) {
    if (p is List && p.length == 2) {
      final a = '${p[0]}', b = '${p[1]}';
      if (a == b) continue;
      links.putIfAbsent(a, () => <String>{}).add(b);
      links.putIfAbsent(b, () => <String>{}).add(a);
    }
  }

  final notes = <String, String>{};
  final n = m['notes'] as Map? ?? {};
  for (final k in n.keys) {
    notes['$k'] = '${n[k]}';
  }

  st.replaceAll(items: items, counters: counters, links: links, notes: notes);
}

/// ====================== CONSULTA (v3) ======================

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
