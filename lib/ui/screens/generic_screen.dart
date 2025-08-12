import 'package:flutter/material.dart';
import 'package:caosbox/config/blocks.dart';
import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/core/models/enums.dart';

import 'package:caosbox/domain/search/search_models.dart';
import 'package:caosbox/ui/widgets/content_block.dart';

class GenericScreen extends StatelessWidget {
  final Block block;
  final AppState state;
  final SearchSpec spec;
  final String quickQuery;
  final ValueChanged<String> onQuickQuery;
  final Future<void> Function(BuildContext, ItemType) onOpenFilters;

  const GenericScreen({
    super.key,
    required this.block,
    required this.state,
    required this.spec,
    required this.quickQuery,
    required this.onQuickQuery,
    required this.onOpenFilters,
  });

  @override
  Widget build(BuildContext context) {
    final t = block.type!;
    return ContentBlock(
      state: state,
      types: { t },
      spec: spec,
      quickQuery: quickQuery,
      onQuickQuery: onQuickQuery,
      onOpenFilters: () => onOpenFilters(context, t),
      showComposer: true,
      mode: ContentBlockMode.list,
      checkboxSide: CheckboxSide.none,
    );
  }
}
