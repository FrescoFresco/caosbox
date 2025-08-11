import 'package:flutter/material.dart';
import 'package:caosbox/core/models/enums.dart';
import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/ui/screens/generic_screen.dart';
import 'package:caosbox/ui/screens/links_block.dart';

typedef ScreenBuilder = Widget Function(BuildContext, AppState);

class Block {
  final String id;
  final IconData icon;
  final String label;
  final ItemType? type;
  final ScreenBuilder? custom;

  const Block.item({
    required this.id,
    required this.icon,
    required this.label,
    required this.type,
  }) : custom = null;

  const Block.custom({
    required this.id,
    required this.icon,
    required this.label,
    required this.custom,
  }) : type = null;
}

final blocks = <Block>[
  const Block.item(id: 'ideas',   icon: Icons.lightbulb, label: 'Ideas',    type: ItemType.idea),
  const Block.item(id: 'actions', icon: Icons.assignment, label: 'Acciones', type: ItemType.action),
  const Block.custom(id: 'links', icon: Icons.link, label: 'Enlaces',       custom: (ctx, st) => LinksBlock(state: st)),
];
