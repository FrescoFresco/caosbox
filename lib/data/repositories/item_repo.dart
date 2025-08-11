import 'package:caosbox/core/models/item.dart';
import 'package:caosbox/core/models/enums.dart';
import 'package:flutter/foundation.dart';

abstract class ItemRepository extends ChangeNotifier {
  List<Item> getAllByType(ItemType t);
  Map<ItemType,int> getCounters();

  void add(ItemType t, String text);
  bool updateText(String id, String text);
  bool setStatus(String id, ItemStatus status);

  List<Item> get all;
  Item? byId(String id);
  void replaceAll({required List<Item> items, required Map<ItemType,int> counters});
}
