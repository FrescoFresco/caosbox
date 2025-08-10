import '../models/item.dart';

class DataValidationError implements Exception {
  final String message;
  DataValidationError(this.message);
  @override
  String toString() => 'DataValidationError: $message';
}

class DataValidator {
  static List<Map<String, String>> canonicalizeLinks(Iterable<Map<String, String>> raw) {
    final set = <String>{};
    final out = <Map<String, String>>[];
    for (final e in raw) {
      final a = e['a'] ?? '';
      final b = e['b'] ?? '';
      if (a.isEmpty || b.isEmpty || a == b) continue;
      final p = (a.compareTo(b) < 0) ? '$a|$b' : '$b|$a';
      if (set.add(p)) {
        final parts = p.split('|');
        out.add({'a': parts[0], 'b': parts[1]});
      }
    }
    return out;
  }

  static void validate({required List<Item> items, required List<Map<String, String>> links}) {
    final ids = <String>{};
    for (final it in items) {
      if (!ids.add(it.id)) {
        throw DataValidationError('ID duplicado: ${it.id}');
      }
    }
    for (final e in links) {
      final a = e['a'], b = e['b'];
      if (a == null || b == null) throw DataValidationError('Link inválido (a/b null)');
      if (a == b) throw DataValidationError('Link con bucle: $a == $b');
      if (!ids.contains(a) || !ids.contains(b)) throw DataValidationError('Link a ID inexistente: $a <-> $b');
    }
  }
}
