import 'package:caosbox/core/models/item.dart';
import 'package:caosbox/core/models/enums.dart';
import 'package:caosbox/data/repositories/item_repo.dart';

class InMemoryItemRepo extends ItemRepository {
  final Map<ItemType, List<Item>> _items = { ItemType.idea: [], ItemType.action: [] };
  final Map<ItemType, int> _cnt = { ItemType.idea: 0, ItemType.action: 0 };
  final Map<String, Item> _cache = {};

  void _reindex(){ _cache..clear()..addAll({for(final it in all) it.id: it}); }

  @override List<Item> getAllByType(ItemType t) => List.unmodifiable(_items[t]!);
  @override Map<ItemType,int> getCounters() => Map.unmodifiable(_cnt);
  @override List<Item> get all => _items.values.expand((e) => e).toList(growable: false);
  @override Item? byId(String id) => _cache[id];

  @override
  void add(ItemType t, String text) {
    final v = text.trim(); if (v.isEmpty) return;
    _cnt[t] = (_cnt[t] ?? 0) + 1;
    final prefix = (t == ItemType.idea) ? 'B1' : 'B2';
    final id = '$prefix${_cnt[t]!.toString().padLeft(3, '0')}';
    _items[t]!.insert(0, Item(id, v, t));
    _reindex(); notifyListeners();
  }

  @override
  bool updateText(String id, String text) {
    final it = _cache[id]; if (it == null) return false;
    final L = _items[it.type]!;
    final i = L.indexWhere((e) => e.id == id); if (i < 0) return false;
    L[i] = it.copyWith(text: text, modifiedAt: DateTime.now());
    _reindex(); notifyListeners(); return true;
  }

  @override
  bool setStatus(String id, ItemStatus status) {
    final it = _cache[id]; if (it == null) return false;
    final L = _items[it.type]!;
    final i = L.indexWhere((e) => e.id == id); if (i < 0) return false;
    final chg = status != it.status;
    L[i] = it.copyWith(
      status: status,
      modifiedAt: DateTime.now(),
      statusChanges: chg ? it.statusChanges + 1 : it.statusChanges,
    );
    _reindex(); notifyListeners(); return true;
  }

  @override
  void replaceAll({required List<Item> items, required Map<ItemType,int> counters}) {
    _items[ItemType.idea] = items.where((e)=>e.type==ItemType.idea).toList();
    _items[ItemType.action] = items.where((e)=>e.type==ItemType.action).toList();
    _cnt
      ..clear()
      ..addAll({ ItemType.idea: counters[ItemType.idea] ?? 0, ItemType.action: counters[ItemType.action] ?? 0 });
    _reindex(); notifyListeners();
  }
}
