import 'dart:convert';
import '../models/enums.dart';
import '../models/item.dart';
import '../state/app_state.dart';
import 'validator.dart';
import 'schema.dart';

enum ImportKind { query, data, unknown }

ImportKind detectJsonType(String jsonStr) {
  try {
    final j = jsonDecode(jsonStr) as Map<String, dynamic>;
    final t = j['type'];
    if (t == 'query') return ImportKind.query;
    if (t == 'data') return ImportKind.data;
    return ImportKind.unknown;
  } catch (_) {
    return ImportKind.unknown;
  }
}

String exportDataV2(AppState st) {
  final set = <String>{};
  final pairs = <Map<String, String>>[];
  for (final e in st.all) {
    final a = e.id;
    for (final b in st.links(a)) {
      if (a == b) continue;
      final key = (a.compareTo(b) < 0) ? '$a|$b' : '$b|$a';
      if (set.add(key)) {
        final parts = key.split('|');
        pairs.add({'a': parts[0], 'b': parts[1]});
      }
    }
  }

  final items = st.all
      .map((it) => {
            'id': it.id,
            'type': switch (it.type) { ItemType.idea => 'idea', ItemType.action => 'action' },
            'status': switch (it.status) {
              ItemStatus.normal => 'normal',
              ItemStatus.completed => 'completed',
              ItemStatus.archived => 'archived'
            },
            'content': it.text,
            'note': st.note(it.id),
            'createdAt': it.createdAt.toIso8601String(),
            'modifiedAt': it.modifiedAt.toIso8601String(),
            'statusChanges': it.statusChanges,
          })
      .toList();

  DataValidator.validate(items: st.all, links: pairs);

  return jsonEncode({
    'version': 2,
    'schema': caosSchemaV2(),
    'type': 'data',
    'data': {
      'counters': {'idea': 0, 'action': 0},
      'items': items,
      'links': pairs,
    }
  });
}

void importDataV2Replace(AppState st, String jsonStr) {
  final j = jsonDecode(jsonStr) as Map<String, dynamic>;
  if (j['type'] != 'data') throw Exception('No es JSON de datos');
  final ver = (j['version'] as num?)?.toInt() ?? 1;
  final data = (j['data'] as Map).cast<String, dynamic>();

  List<Map<String, String>> links;
  if (ver >= 2 && data.containsKey('links')) {
    links = (data['links'] as List).map((e) => (e as Map).cast<String, String>()).toList();
  } else {
    final tmp = <String>{};
    final out = <Map<String, String>>[];
    final itemsRaw = (data['items'] as List).cast<Map>();
    for (final r in itemsRaw) {
      final m = r.cast<String, dynamic>();
      final a = m['id'] as String;
      final L = (m['links'] as List? ?? const []).cast<String>();
      for (final b in L) {
        if (a == b) continue;
        final key = (a.compareTo(b) < 0) ? '$a|$b' : '$b|$a';
        if (tmp.add(key)) {
          final parts = key.split('|');
          out.add({'a': parts[0], 'b': parts[1]});
        }
      }
      m.remove('links');
    }
    links = out;
  }

  final items = <Item>[];
  final notes = <String, String>{};
  final itemsRaw = (data['items'] as List).cast<Map>();
  for (final r in itemsRaw) {
    final m = r.cast<String, dynamic>();
    final type = m['type'] == 'idea' ? ItemType.idea : ItemType.action;
    final status = switch (m['status']) {
      'completed' => ItemStatus.completed,
      'archived' => ItemStatus.archived,
      _ => ItemStatus.normal,
    };
    final created = DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now();
    final modified = DateTime.tryParse(m['modifiedAt'] ?? '') ?? created;
    final sc = (m['statusChanges'] as num?)?.toInt() ?? 0;
    final it = Item(m['id'] as String, m['content'] as String, type, status, created, modified, sc);
    items.add(it);
    final n = (m['note'] as String?) ?? '';
    if (n.isNotEmpty) notes[it.id] = n;
  }

  final canon = DataValidator.canonicalizeLinks(links);
  DataValidator.validate(items: items, links: canon);

  final linkMap = <String, Set<String>>{};
  for (final e in canon) {
    final a = e['a']!, b = e['b']!;
    linkMap.putIfAbsent(a, () => <String>{}).add(b);
    linkMap.putIfAbsent(b, () => <String>{}).add(a);
  }

  st.replaceAll(
    items: items,
    counters: {ItemType.idea: 0, ItemType.action: 0},
    notes: notes,
    links: linkMap,
  );
}
