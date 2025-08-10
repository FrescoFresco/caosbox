import 'dart:convert';
import '../data/schema.dart';
import '../data/serializer.dart';
import '../state/app_state.dart';
import 'search_models.dart';

String exportQueryJson(SearchSpec spec) => jsonEncode({
  'version': 2,
  'schema': caosSchemaV2(),
  'type': 'query',
  'query': spec.toJson(),
});

SearchSpec importQueryJson(String jsonStr) {
  final j = jsonDecode(jsonStr) as Map<String, dynamic>;
  if (j['type'] != 'query') throw Exception('No es un JSON de consulta');
  return SearchSpec.fromJson((j['query'] as Map).cast<String, dynamic>());
}

String exportDataJson(AppState st) => exportDataV2(st);
void importDataJsonReplace(AppState st, String jsonStr) => importDataV2Replace(st, jsonStr);

ImportKind detectJsonTypeQuick(String jsonStr) => detectJsonType(jsonStr);
