import 'package:caosbox/data/repositories/link_repo.dart';

class InMemoryLinkRepo extends LinkRepository {
  final Map<String, Set<String>> _links = {};

  @override Set<String> linksOf(String id) => _links[id] ?? const <String>{};

  @override
  void toggle(String a, String b) {
    if (a == b) return;
    final sa = _links.putIfAbsent(a, () => <String>{});
    final sb = _links.putIfAbsent(b, () => <String>{});
    if (sa.remove(b)) { sb.remove(a); } else { sa.add(b); sb.add(a); }
    notifyListeners();
  }

  @override
  void replaceAll(Map<String, Set<String>> links) {
    _links..clear()..addAll({ for (final e in links.entries) e.key: {...e.value} });
    notifyListeners();
  }
}
