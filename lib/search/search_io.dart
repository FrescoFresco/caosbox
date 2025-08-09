// Exportar/Importar JSON (búsqueda y datos) – mismo “sobre” JSON.

import 'dart:convert';
import '../models/item.dart';
import '../models/enums.dart';
import '../state/app_state.dart';
import 'search_models.dart';

Map<String, dynamic> _schema() => {
  'fields': {
    'type':   {'kind':'enum', 'values':['idea','action']},
    'status': {'kind':'enum', 'values':['normal','completed','archived']},
    'id':      {'kind':'text'},
    'content': {'kind':'text'},
    'note':    {'kind':'text'},
  },
  'computed': {
    'hasLinks': {'kind':'enum','values':['true','false']},
  }
};

/// --------- QUERY (búsqueda)
String exportQueryJson(SearchSpec spec) => jsonEncode({
  'version': 1,
  'schema': _schema(),
  'type': 'query',
  'query': spec.toJson(),
});

SearchSpec importQueryJson(String jsonStr) {
  final j = jsonDecode(jsonStr) as Map<String, dynamic>;
  if (j['type'] != 'query') { throw Exception('No es un JSON de consulta'); }
  return SearchSpec.fromJson((j['query'] as Map).cast<String, dynamic>());
}

/// --------- DATA (datos)
String exportDataJson(AppState st) {
  final items = st.all.map((it) => {
    'id': it.id,
    'type': switch (it.type) { ItemType.idea=>'idea', ItemType.action=>'action' },
    'status': switch (it.status) {
      ItemStatus.normal=>'normal', ItemStatus.completed=>'completed', ItemStatus.archived=>'archived'
    },
    'content': it.text,
    'note': st.note(it.id),
    'createdAt': it.createdAt.toIso8601String(),
    'modifiedAt': it.modifiedAt.toIso8601String(),
    'statusChanges': it.statusChanges,
    'links': st.links(it.id).toList(),
  }).toList();

  return jsonEncode({
    'version': 1,
    'schema': _schema(),
    'type': 'data',
    'data': {
      'counters': {'idea': 0, 'action': 0}, // puedes rellenar con tus contadores
      'items': items,
    }
  });
}

// Importar datos (muestra simple: reemplazar todo). Puedes ampliar a "combinar".
void importDataJsonReplace(AppState st, String jsonStr) {
  final j = jsonDecode(jsonStr) as Map<String, dynamic>;
  if (j['type'] != 'data') { throw Exception('No es un JSON de datos'); }
  final data = (j['data'] as Map).cast<String, dynamic>();
  final items = (data['items'] as List).cast<Map>();

  // Limpia
  // (no expongo limpieza total porque AppState es solo de muestra; ajusta a tus necesidades)
  // st.clear(); // si lo implementas

  for (final raw in items) {
    final m = raw.cast<String, dynamic>();
    final type = m['type'] == 'idea' ? ItemType.idea : ItemType.action;
    st.add(type, m['content'] as String);
    // Podrías mapear ID/estado/nota/enlaces con métodos nuevos en AppState (setters públicos).
  }
}
