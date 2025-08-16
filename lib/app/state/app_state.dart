import 'package:flutter/foundation.dart';
import 'package:caosbox/core/models/enums.dart';
import 'package:caosbox/core/models/item.dart';
import 'package:caosbox/data/fire_repo.dart';

class AppState extends ChangeNotifier {
  final Map<ItemType, List<Item>> _items = {ItemType.idea: [], ItemType.action: []};
  final Map<String, Set<String>> _links = {};
  final Map<ItemType, int> _cnt = {ItemType.idea: 0, ItemType.action: 0};
  final Map<String, Item> _cache = {};
  final Map<String, String> _notes = {};

  FireRepo? _repo;

  String note(String id) => _notes[id] ?? '';
  List<Item> items(ItemType t) => List.unmodifiable(_items[t]!);
  List<Item> get all => _items.values.expand((e) => e).toList();
  Set<String> links(String id) => _links[id] ?? const <String>{};
  Item? getItem(String id) => _cache[id];
  Map<ItemType, int> get counters => Map.unmodifiable(_cnt);

  void attachRepo(FireRepo repo) {
    _repo?.dispose();
    _repo = repo;
    _repo!.subscribe(onRemoteData);
  }

  void onRemoteData({
    required List<Item> items,
    required Map<String, Set<String>> links,
    required Map<ItemType, int> counters,
    required Map<String, String> notes,
  }) {
    _items[ItemType.idea] = items.where((e) => e.type == ItemType.idea).toList();
    _items[ItemType.action] = items.where((e) => e.type == ItemType.action).toList();
    _links..clear()..addAll(links);
    _cnt..clear()..addAll(counters);
    _notes..clear()..addAll(notes);
    _reindex(); notifyListeners();
  }

  void add(ItemType t, String text) {
    final v = text.trim(); if (v.isEmpty) return;
    if (_repo != null) { _repo!.addItem(t, v); return; }

    _cnt[t] = (_cnt[t] ?? 0) + 1;
    final pref = (t == ItemType.idea) ? 'B1' : 'B2';
    final id = '$pref${_cnt[t]!.toString().padLeft(3, '0')}';
    _items[t]!.insert(0, Item(id, v, t,
      status: ItemStatus.normal, createdAt: DateTime.now(), modifiedAt: DateTime.now(), statusChanges: 0));
    _reindex(); notifyListeners();
  }

  bool _up(String id, Item Function(Item) ch) {
    final it = _cache[id]; if (it == null) return false;
    final L = _items[it.type]!, i = L.indexWhere((e)=>e.id==id); if (i<0) return false;
    final next = ch(it); L[i] = next;

    if (_repo != null) {
      if (next.text != it.text) { _repo!.updateText(id, next.text); }
      if (next.status != it.status || next.statusChanges != it.statusChanges) {
        _repo!.setStatus(id, next.status, next.statusChanges);
      }
    }
    _reindex(); notifyListeners(); return true;
  }

  bool setStatus(String id, ItemStatus s) => _up(id, (it)=>it.copyWith(status: s));
  bool updateText(String id, String t) => _up(id,(it)=>Item(it.id,t,it.type,
    status: it.status, createdAt: it.createdAt, modifiedAt: DateTime.now(), statusChanges: it.statusChanges));

  void toggleLink(String a, String b) {
    if (a==b || _cache[a]==null || _cache[b]==null) return;
    final sa=_links.putIfAbsent(a,()=> <String>{}), sb=_links.putIfAbsent(b,()=> <String>{});
    if (sa.remove(b)) { sb.remove(a); } else { sa.add(b); sb.add(a); }
    notifyListeners();
    if (_repo!=null) { _repo!.toggleLink(a,b); }
  }

  void setNote(String id, String v) { _notes[id]=v; notifyListeners(); if (_repo!=null) _repo!.setNote(id,v); }

  void _reindex(){ _cache..clear()..addAll({for(final it in all) it.id:it}); }

  void replaceAll({
    required List<Item> items,
    required Map<ItemType, int> counters,
    required Map<String, Set<String>> links,
    required Map<String, String> notes,
  }) {
    _items[ItemType.idea]=items.where((e)=>e.type==ItemType.idea).toList();
    _items[ItemType.action]=items.where((e)=>e.type==ItemType.action).toList();
    _cnt..clear()..addAll(counters);
    _links..clear()..addAll(links);
    _notes..clear()..addAll(notes);
    _reindex(); notifyListeners();
  }

  @override
  void dispose(){ _repo?.dispose(); super.dispose(); }
}
