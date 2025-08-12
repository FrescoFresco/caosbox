import 'package:flutter/material.dart';
import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/core/models/enums.dart';
import 'package:caosbox/domain/search/search_models.dart';
import 'package:caosbox/ui/widgets/content_block.dart';

/// Wrapper legacy para proyectos que aún referencian ItemsBlock.
/// Internamente delega en ContentBlock (modo list).
class ItemsBlock extends StatelessWidget {
  final AppState state;
  final Set<ItemType>? types;
  final SearchSpec spec;
  final String quickQuery;
  final ValueChanged<String> onQuickQuery;
  final Future<void> Function(BuildContext, ItemType) onOpenFilters;
  final bool showComposer;

  const ItemsBlock({
    super.key,
    required this.state,
    this.types,
    required this.spec,
    required this.quickQuery,
    required this.onQuickQuery,
    required this.onOpenFilters,
    this.showComposer = true,
  });

  @override
  Widget build(BuildContext context) {
    // Si se pasa un solo tipo, lo usamos; si no, ContentBlock maneja null=todos
    Set<ItemType>? t = types;
    return ContentBlock(
      state: state,
      types: t,
      spec: spec,
      quickQuery: quickQuery,
      onQuickQuery: onQuickQuery,
      onOpenFilters: () async {
        // si hay un único tipo, pásalo a tu modal
        final type = (t != null && t.length == 1) ? t.first : ItemType.idea;
        await onOpenFilters(context, type);
      },
      showComposer: showComposer,
      mode: ContentBlockMode.list,
      checkboxSide: CheckboxSide.none,
    );
  }
}
