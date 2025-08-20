import '../models/item.dart';

abstract class Repo {
  // Items
  Stream<List<Item>> streamByType(ItemType t);
  Stream<Item?> streamItem(String id);
  Future<String> addItem(ItemType t, {required String text, String note = '', List<String> tags = const []});
  Future<void> updateItem(Item it);
  Future<void> setStatus(String id, ItemStatus s);
  Future<void> deleteItem(String id);

  // Links
  Stream<Set<String>> streamLinksOf(String id);
  Future<void> link(String a, String b);
  Future<void> unlink(String a, String b);
  Future<bool> hasLink(String a, String b);
}

String canonicalKey(String a, String b) {
  if (a.compareTo(b) <= 0) return '${a}_$b';
  return '${b}_$a';
}
