import '../models/models.dart' as models;

class FilterEngine {
  static List<models.Item> apply(List<models.Item> items, models.AppState st, models.FilterSet set) {
    final q = set.text.text.toLowerCase();
    return items.where((it) => it.text.toLowerCase().contains(q)).toList();
  }
}
