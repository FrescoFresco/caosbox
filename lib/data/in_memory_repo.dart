import 'dart:async';
import '../models/item.dart';
import 'repo.dart';

class InMemoryRepo implements Repo {
  final Map<String, Item> _items = {};
  final Map<String, Set<String>> _links = {}; // id -> peers

  final Map<ItemType, StreamController<List<Item>>> _byTypeCtrls = {
    ItemType.b1: StreamController<List<Item>>.broadcast(),
    ItemType.b2: StreamController<List<Item>>.broadcast(),
  };
  final Map<String, StreamController<Set<String>>> _linksCtrls = {};
  final Map<String, StreamController<Item?>> _itemCtrls = {};

  InMemoryRepo._();

  static InMemoryRepo seed() {
    final r = InMemoryRepo._();
    for (int i = 1; i <= 6; i++) {
      r._add(Item(
        id: 'b1_$i',
        type: ItemType.b1,
        text: 'Idea $i',
        note: 'Nota de la idea $i',
        status: ItemStatus.normal,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      r._add(Item(
        id: 'b2_$i',
        type: ItemType.b2,
        text: 'Acción $i',
        note: 'Nota de la acción $i',
        status: i.isEven ? ItemStatus.completed : ItemStatus.normal,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }
    r.link('b1_2', 'b2_3');
    r.link('b1_2', 'b2_5');
    return r;
  }

  void _add(Item it) { _items[it.id] = it; _emit(); }

  void _emit() {
    final b1 = _items.values.where((e) => e.type == ItemType.b1).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final b2 = _items.values.where((e) => e.type == ItemType.b2).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _byTypeCtrls[ItemType.b1]!.add(b1);
    _byTypeCtrls[ItemType.b2]!.add(b2);

    for (final id in _linksCtrls.keys) {
      _linksCtrls[id]!.add(Set.of(_links[id] ?? <String>{}));
    }
    for (final id in _itemCtrls.keys) {
      _itemCtrls[id]!.add(_items[id]);
    }
  }

  @override
  Stream<List<Item>> streamByType(ItemType t) => _byTypeCtrls[t]!.stream;

  @override
  Stream<Item?> streamItem(String id) {
    final ctrl = _itemCtrls[id] ??= StreamController<Item?>.broadcast();
    Future.microtask(() => ctrl.add(_items[id]));
    return ctrl.stream;
  }

  @override
  Future<String> addItem(ItemType t, {required String text, String note = ''}) async {
    final id = '${t == ItemType.b1 ? 'b1' : 'b2'}_${DateTime.now().millisecondsSinceEpoch}';
    _add(Item(
      id: id,
      type: t,
      text: text,
      note: note,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    return id;
  }

  @override
  Future<void> updateItem(Item it) async {
    _items[it.id] = it.copyWith(updatedAt: DateTime.now());
    _emit();
  }

  @override
  Future<void> setStatus(String id, ItemStatus s) async {
    final it = _items[id];
    if (it == null) return;
    _items[id] = it.copyWith(status: s, updatedAt: DateTime.now());
    _emit();
  }

  @override
  Future<void> deleteItem(String id) async {
    _items.remove(id);
    _links.remove(id);
    for (final peers in _links.values) {
      peers.remove(id);
    }
    _emit();
  }

  @override
  Stream<Set<String>> streamLinksOf(String id) {
    final ctrl = _linksCtrls[id] ??= StreamController<Set<String>>.broadcast();
    Future.microtask(() => ctrl.add(Set.of(_links[id] ?? <String>{})));
    return ctrl.stream;
  }

  @override
  Future<void> link(String a, String b) async {
    if (a == b) return;
    _links.putIfAbsent(a, () => <String>{}).add(b);
    _links.putIfAbsent(b, () => <String>{}).add(a);
    _emit();
  }

  @override
  Future<void> unlink(String a, String b) async {
    _links[a]?.remove(b);
    _links[b]?.remove(a);
    _emit();
  }

  @override
  Future<bool> hasLink(String a, String b) async => _links[a]?.contains(b) ?? false;
}
