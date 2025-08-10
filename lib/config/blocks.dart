import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../state/app_state.dart';
import '../ui/screens/links_block.dart';

class ItemTypeCfg {
  final String prefix, hint, label;
  final IconData icon;
  const ItemTypeCfg({required this.prefix, required this.icon, required this.label, required this.hint});
}

typedef BlockBuilder = Widget Function(BuildContext, AppState);

class Block {
  final String id;
  final IconData icon;
  final String label;
  final ItemType? type;
  final ItemTypeCfg? cfg;
  final BlockBuilder? custom;

  const Block.item({required this.id, required this.icon, required this.label, required this.type, required this.cfg})
      : custom = null;

  const Block.custom({required this.id, required this.icon, required this.label, required this.custom})
      : type = null,
        cfg = null;
}

final ideasCfg = ItemTypeCfg(prefix: 'B1', icon: Icons.lightbulb, label: 'Ideas', hint: 'Escribe tu idea...');
final actionsCfg = ItemTypeCfg(prefix: 'B2', icon: Icons.assignment, label: 'Acciones', hint: 'Describe la acción...');

final blocks = <Block>[
  Block.item(id: 'ideas', icon: ideasCfg.icon, label: ideasCfg.label, type: ItemType.idea, cfg: ideasCfg),
  Block.item(id: 'actions', icon: actionsCfg.icon, label: actionsCfg.label, type: ItemType.action, cfg: actionsCfg),
  Block.custom(id: 'links', icon: Icons.link, label: 'Enlaces', custom: (ctx, st) => LinksBlock(st: st)),
];
