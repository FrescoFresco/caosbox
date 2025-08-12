import 'package:flutter/material.dart';

import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/core/models/enums.dart';
import 'package:caosbox/ui/screens/links_block.dart';

/// Config básica por tipo (B1/B2)
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

const ideasCfg  = ItemTypeCfg(
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

  /// Si es un bloque de items (Ideas/Acciones), indica el tipo;
  /// si es un bloque totalmente custom (Enlaces), usa [custom].
  final ItemType? type;
  final BlockBuilder? custom;

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

/// 🔧 Puente provisional para abrir el modal de “Búsqueda avanzada”.
/// Sustituye el contenido por tu modal REAL (el mismo que usas en B1/B2).
Future<void> openAdvancedFilters(BuildContext c) async {
  await showModalBottomSheet(
    context: c,
    builder: (_) => const SafeArea(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Aquí se abre tu modal real de Búsqueda avanzada (mismo que B1/B2).'),
      ),
    ),
  );
}

/// Lista de pestañas (B1, B2, Enlaces)
final blocks = <Block>[
  const Block.item(
    id: 'ideas',
    icon: ideasCfg.icon,
    label: ideasCfg.label,
    type: ItemType.idea,
  ),
  const Block.item(
    id: 'actions',
    icon: actionsCfg.icon,
    label: actionsCfg.label,
    type: ItemType.action,
  ),

  // Enlaces: usa el MISMO modal de filtros avanzado que B1/B2 (a través del callback).
  Block.custom(
    id: 'links',
    icon: Icons.link,
    label: 'Enlaces',
    custom: (ctx, st) => LinksBlock(
      state: st,
      onOpenFilters: (c) => openAdvancedFilters(c), // ← reemplaza por tu función real si ya la tienes
    ),
  ),
];
