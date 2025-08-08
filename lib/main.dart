// lib/src/models/models.dart
import 'package:flutter/material.dart';

enum ItemType   { idea, action }
enum ItemStatus { normal, completed, archived }

/*──────────────────────────────────────────────────────────────────────────*/
/*  MODELO PRINCIPAL                                                        */
/*──────────────────────────────────────────────────────────────────────────*/

class Item {
  Item(this.id, this.text, this.type,
      {this.status = ItemStatus.normal,
       DateTime? created,
       DateTime? modified,
       this.statusChanges = 0})
      : createdAt  = created  ?? DateTime.now(),
        modifiedAt = modified ?? DateTime.now();

  final String     id;
  final String     text;
  final ItemType   type;
  final ItemStatus status;
  final DateTime   createdAt;
  final DateTime   modifiedAt;
  final int        statusChanges;

  Item copyWith({ItemStatus? status}) => Item(
        id,
        text,
        type,
        status: status ?? this.status,
        created: createdAt,
        modified: DateTime.now(),
        statusChanges: statusChanges + 1,
      );
}

/*──────────────────────────────────────────────────────────────────────────*/
/*  ESTADO GLOBAL                                                           */
/*──────────────────────────────────────────────────────────────────────────*/

class AppState extends ChangeNotifier {
  final _items = <ItemType, List<Item>>{
    ItemType.idea  : <Item>[],
    ItemType.action: <Item>[],
  };

  List<Item> items(ItemType t) => List.unmodifiable(_items[t]!);

  void add(ItemType t, String txt) {
    final id = '${t == ItemType.idea ? 'B1' : 'B2'}${_items[t]!.length + 1}';
    _items[t]!.insert(0, Item(id, txt.trim(), t));
    notifyListeners();
  }
}

/*──────────────────────────────────────────────────────────────────────────*/
/*  CONFIG VISUAL POR TIPO                                                  */
/*──────────────────────────────────────────────────────────────────────────*/

class ItemTypeCfg {
  const ItemTypeCfg({
    required this.prefix,
    required this.icon,
    required this.label,
    required this.hint,
  });

  final String   prefix;
  final IconData icon;
  final String   label;
  final String   hint;
}

const ideasCfg   = ItemTypeCfg(
  prefix: 'B1',
  icon  : Icons.lightbulb,
  label : 'Ideas',
  hint  : 'Escribe una idea…',
);

const actionsCfg = ItemTypeCfg(
  prefix: 'B2',
  icon  : Icons.assignment,
  label : 'Acciones',
  hint  : 'Describe una acción…',
);

/*──────────────────────────────────────────────────────────────────────────*/
/*  FILTROS – UTILIDAD SENCILLA                                             */
/*──────────────────────────────────────────────────────────────────────────*/

class FilterSet {
  final text = TextEditingController();
  void dispose() => text.dispose();
}
