import 'dart:convert';
import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/core/models/enums.dart';
import 'package:caosbox/core/models/item.dart';
import 'package:caosbox/core/utils/tri.dart';
import 'package:caosbox/domain/search/search_models.dart';

/// ---------------------- DATOS (items) ----------------------

String exportDataJson(AppState st) {
  final data = {
    'kind': 'caosbox-data',
    'version': 1,
    'meta': {
      'counters': {
        'idea': st.counters[ItemType.idea] ?? 0,
        'action': st.counters[ItemType.action] ?? 0
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
      final x = a.compareTo(b) <= 0 ? '$a|$b' : '$b|$a';
      if (seen.add(x)) {
        final pair = a.compareTo(b) <= 0 ? [a, b] : [b, a];
        out.add(pair);
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
      _           => ItemStatus.normal
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

  // reconstruir adyacencia desde pares
  final links = <String, Set<String>>{};
  for (final p in (m['links'] as List? ?? [])) {
    if (p is List && p.length == 2) {
      final a = '${p[0]}';
      final b = '${p[1]}';
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

/// ---------------------- QUERY (búsqueda) ----------------------

String exportQueryJson(SearchSpec s) {
  Map<String, dynamic> clauseToMap(Clause c) {
    if (c is EnumClause) {
      return {
        'type': 'enum',
        'field': c.field,
        'include': c.include.toList(),
        'exclude': c.exclude.toList()
      };
    } else if (c is TextClause) {
      return {
        'type': 'text',
        'fields': c.fields.map((k, v) => MapEntry(k, v.name)),
        'tokens': [for (final t in c.tokens) {'t': t.t, 'mode': t.mode.name}],
        'match': switch (c.match) {
          TextMatch.prefix => 'prefix',
          TextMatch.exact => 'exact',
          _ => 'contains'
        },
      };
    } else if (c is BoolClause) {
      return {
        'type': 'bool',
        'field': c.field,
        'mode': c.mode.name,
      };
    } else if (c is RelationClause) {
      return {
        'type': 'relation',
        'anchorId': c.anchorId,
        'mode': c.mode.name,
      };
    }
    return {};
  }

  final obj = {
    'kind': 'caosbox-query',
    'version': 2,
    'clauses': [for (final c in s.clauses) clauseToMap(c)],
  };
  return const JsonEncoder.withIndent('  ').convert(obj);
}

SearchSpec importQueryJson(String text) {
  final m = json.decode(text);
  if (m is! Map || m['kind'] != 'caosbox-query') {
    throw 'Documento inválido (kind != caosbox-query)';
  }
  final clauses = <Clause>[];

  for (final e in (m['clauses'] as List? ?? [])) {
    final t = '${e['type']}';
    if (t == 'enum') {
      clauses.add(EnumClause(
        field: '${e['field']}',
        include: {...(e['include'] as List? ?? []).map((x) => '$x')},
        exclude: {...(e['exclude'] as List? ?? []).map((x) => '$x')},
      ));
    } else if (t == 'text') {
      final fields = <String, Tri>{};
      final fm = (e['fields'] as Map? ?? {});
      for (final k in fm.keys) {
        final v = '${fm[k]}';
        fields['$k'] = switch (v) {
          'include' => Tri.include,
          'exclude' => Tri.exclude,
          _ => Tri.off
        };
      }
      final toks = <Token>[
        for (final t in (e['tokens'] as List? ?? []))
          Token(
            '${t['t']}',
            switch ('${t['mode']}') {
              'exclude' => Tri.exclude,
              'include' => Tri.include,
              _ => Tri.off
            },
          )
      ];
      final match = switch ('${e['match']}') {
        'prefix' => TextMatch.prefix,
        'exact' => TextMatch.exact,
        _ => TextMatch.contains,
      };
      clauses.add(TextClause(fields: fields, tokens: toks, match: match));
    } else if (t == 'bool') {
      clauses.add(BoolClause(
        field: '${e['field']}',
        mode: switch ('${e['mode']}') {
          'include' => Tri.include,
          'exclude' => Tri.exclude,
          _ => Tri.off
        },
      ));
    } else if (t == 'relation') {
      clauses.add(RelationClause(
        anchorId: '${e['anchorId']}',
        mode: switch ('${e['mode']}') {
          'include' => Tri.include,
          'exclude' => Tri.exclude,
          _ => Tri.off
        },
      ));
    }
  }

  return SearchSpec(clauses: clauses);
}
