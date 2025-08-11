import 'package:flutter/foundation.dart';
import 'package:caosbox/core/models/enums.dart';
import 'package:caosbox/core/models/item.dart';
import 'package:caosbox/data/memory/item_repo_mem.dart';
import 'package:caosbox/data/memory/link_repo_mem.dart';
import 'package:caosbox/data/repositories/item_repo.dart';
import 'package:caosbox/data/repositories/link_repo.dart';

class AppState extends ChangeNotifier {
  final ItemRepository _items;
  final LinkRepository _links;
  final Map<String, String> _notes = {};

  AppState({ItemRepository? items, LinkRepository? links})
      : _items = items ?? InMemoryItemRepo(),
        _links = links ?? InMemoryLinkRepo() {
    _items.addListener(notifyListeners);
    _links.addListener(notifyListeners);
  }

  @override void dispose() {
    _items.removeListener(notifyListeners);
    _links.removeListener(notifyListeners);
    super.dispose();
  }

  // Items
  List<Item> items(ItemType t) => _items.getAllByType(t);
  List<Item> get all => _items.all;
  Item? getItem(String id) => _items.byId(id);
  Map<ItemType,int> get counters => _items.getCounters();

  void add(ItemType t, String text) => _items.add(t, text);
  bool setStatus(String id, ItemStatus s) => _items.setStatus(id, s);
  bool updateText(String id, String t) => _items.updateText(id, t);

  // Links
  Set<String> links(String id) => _links.linksOf(id);
  void toggleLink(String a, String b) => _links.toggle(a, b);

  // Notes
  String note(String id) => _notes[id] ?? '';
  void setNote(String id, String v) { _notes[id] = v; notifyListeners(); }

  // Bulk replace (import)
  void replaceAll({
    required List<Item> items,
    required Map<ItemType,int> counters,
    required Map<String, Set<String>> links,
    required Map<String, String> notes,
  }) {
    _items.replaceAll(items: items, counters: counters);
    _links.replaceAll(links);
    _notes
      ..clear()
      ..addAll(notes);
    notifyListeners();
  }
}
