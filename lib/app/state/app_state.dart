// lib/app/state/app_state.dart
import 'package:flutter/foundation.dart';
import 'package:caosbox/core/models/item.dart';
import 'package:caosbox/core/models/enums.dart';
import 'package:caosbox/data/fire_repo.dart';

class AppState extends ChangeNotifier {
  FireRepo? _repo;
  String? _uid;

  bool _loading = false;
  List<Item> _items = [];
  final Map<String, Set<String>> _links = {}; // cache simple por id

  bool get loading => _loading;
  List<Item> get items => List.unmodifiable(_items);

  void attachRepo(FireRepo repo, String uid) async {
    _repo = repo;
    _uid = uid;
    await reload();
  }

  Future<void> reload() async {
    if (_repo == null) return;
    _loading = true; notifyListeners();
    _items = await _repo!.loadItems();
    _links.clear();
    for (final it in _items) {
      _links[it.id] = await _repo!.loadLinksOf(it.id);
    }
    _loading = false; notifyListeners();
  }

  /* ------------ Items ------------ */

  Future<void> addItem(ItemType type, String text) async {
    if (_repo == null) return;
    final id = await _repo!.createItem(type, text);
    _items = [
      ..._items,
      Item(
        id: id,
        type: type,
        text: text,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      )
    ];
    notifyListeners();
  }

  Future<void> updateText(String id, String text) async {
    if (_repo == null) return;
    await _repo!.updateText(id, text);
    _items = _items.map((e) => e.id == id ? e.copyWith(text: text, modifiedAt: DateTime.now()) : e).toList();
    notifyListeners();
  }

  Future<void> toggleCompleted(String id) async {
    if (_repo == null) return;
    final it = _items.firstWhere((e) => e.id == id);
    final next = it.status == ItemStatus.completed ? ItemStatus.normal : ItemStatus.completed;
    await _repo!.setStatus(id, next);
    _items = _items.map((e) => e.id == id ? e.copyWith(status: next, modifiedAt: DateTime.now(), statusChanges: e.statusChanges + 1) : e).toList();
    notifyListeners();
  }

  Future<void> setNote(String id, String note) async {
    if (_repo == null) return;
    await _repo!.setNote(id, note);
    _items = _items.map((e) => e.id == id ? e.copyWith(note: note, modifiedAt: DateTime.now()) : e).toList();
    notifyListeners();
  }

  /* ------------ Links ------------ */

  Set<String> linksOf(String id) => _links[id] ?? <String>{};

  Future<void> link(String a, String b) async {
    if (_repo == null || a == b) return;
    await _repo!.link(a, b);
    _links.putIfAbsent(a, () => <String>{}).add(b);
    _links.putIfAbsent(b, () => <String>{}).add(a);
    notifyListeners();
  }

  Future<void> unlink(String a, String b) async {
    if (_repo == null || a == b) return;
    await _repo!.unlink(a, b);
    _links[a]?.remove(b);
    _links[b]?.remove(a);
    notifyListeners();
  }

  /* ------------ Helpers ------------ */

  List<Item> byType(ItemType t) => _items.where((e) => e.type == t).toList();
}
