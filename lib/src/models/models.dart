import 'package:flutter/material.dart';

enum ItemType { idea, action }
enum ItemStatus { normal, completed, archived }

class Item {
  Item({
    required this.id,
    required this.text,
    required this.type,
    this.status = ItemStatus.normal,
    DateTime? created,
    DateTime? modified,
    this.statusChanges = 0,
  })  : createdAt = created ?? DateTime.now(),
        modifiedAt = modified ?? DateTime.now();

  final String id;
  final String text;
  final ItemType type;
  final ItemStatus status;
  final DateTime createdAt, modifiedAt;
  final int statusChanges;

  Item copyWith({String? text, ItemStatus? status}) {
    final s = status ?? this.status;
    return Item(
      id: id,
      text: text ?? this.text,
      type: type,
      status: s,
      created: createdAt,
      modified: DateTime.now(),
      statusChanges: s == this.status ? statusChanges : statusChanges + 1,
    );
  }
}

class AppState extends ChangeNotifier {
  final _map = <ItemType, List<Item>>{
    ItemType.idea: [],
    ItemType.action: []
  };
  int _cntIdea = 0, _cntAction = 0;

  List<Item> items(ItemType t) => List.unmodifiable(_map[t]!);

  void add(ItemType t, String txt) {
    final id = '${t == ItemType.idea ? 'B1' : 'B2'}${t == ItemType.idea ? ++_cntIdea : ++_cntAction}'.padLeft(4, '0');
    _map[t]!.insert(0, Item(id: id, text: txt.trim(), type: t));
    notifyListeners();
  }

  void setStatus(String id, ItemStatus s) {
    for (final list in _map.values) {
      final idx = list.indexWhere((e) => e.id == id);
      if (idx != -1) {
        list[idx] = list[idx].copyWith(status: s);
        break;
      }
    }
    notifyListeners();
  }
}
