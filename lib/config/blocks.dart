import 'package:flutter/material.dart';

import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/core/models/enums.dart';
import 'package:caosbox/ui/screens/links_block.dart';

// ⬇️ IMPORTA tu callback REAL (el mismo que usa B1/B2) desde donde lo tengas
import 'package:caosbox/app.dart' show openAdvancedFilters; // ajusta la ruta si es otra

/// Config por tipo (B1/B2)
class ItemTypeCfg {
  final String prefix;
  final IconData icon;
  final String label;
  final String hint;
  const ItemTypeCfg({
    required this.prefix,
    required this.icon,
    required this.label,
    required this.hint,
  });
}

const ideasCfg = ItemTypeCfg(
  prefix: 'B1',
  icon: Icons.lightbulb,
  label: 'Ideas',
  hint: 'Escribe tu idea...',
);

const actionsCfg = ItemTypeCfg(
  prefix: 'B2',
  icon: Icons.assignment,
  label: 'Acciones',
  hint: 'Describe la acción...',
);

typedef BlockBuilder = Widget Function(BuildContext ctx, AppState st);

/// Definición de bloque (modular)
class Block {
  final String id;
  final IconData icon;
  final String label;
  final ItemType? type;          // si es item (Ideas/Acciones)
  final BlockBuilder? custom;    // si es custom (Enlaces)

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

/// Pestañas: Ideas, Acciones, Enlaces
final blocks = <Block>[
  // sin `const` para evitar "Not a constant expression" al leer ideasCfg/actionsCfg
  Block.item(
    id: 'ideas',
    icon: ideasCfg.icon,
    label: ideasCfg.label,
    type: ItemType.idea,
  ),
  Block.item(
    id: 'actions',
    icon: actionsCfg.icon,
    label: actionsCfg.label,
    type: ItemType.action,
  ),
  // Enlaces: usa EXACTO el mismo modal de filtros que B1/B2 via callback
  Block.custom(
    id: 'links',
    icon: Icons.link,
    label: 'Enlaces',
    custom: (ctx, st) => LinksBlock(
      state: st,
      onOpenFilters: (c) => openAdvancedFilters(c), // ← tu función real ya existente
    ),
  ),
];
