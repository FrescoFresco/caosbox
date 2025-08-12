import 'package:flutter/material.dart';
import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/domain/search/search_models.dart';
import 'package:caosbox/ui/widgets/content_block.dart';

class LinksBlock extends StatefulWidget {
  final AppState state;
  const LinksBlock({super.key, required this.state});

  @override
  State<LinksBlock> createState() => _LinksBlockState();
}

class _LinksBlockState extends State<LinksBlock> with AutomaticKeepAliveClientMixin {
  String? _selected;
  @override bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    void _noop() {}

    final left = Expanded(
      child: ContentBlock(
        key: const ValueKey('links_left'),
        state: widget.state,
        types: null,
        spec: const SearchSpec(),
        quickQuery: '',
        onQuickQuery: (_) {},
        onOpenFilters: _noop,
        showComposer: false,
        mode: ContentBlockMode.select,
        selectedId: _selected,
        onSelect: (id)=> setState(()=> _selected = id),
        checkboxSide: CheckboxSide.right,
      ),
    );

    final right = Expanded(
      child: ContentBlock(
        key: ValueKey('links_right_${_selected ?? "none"}'),
        state: widget.state,
        types: null,
        spec: const SearchSpec(),
        quickQuery: '',
        onQuickQuery: (_) {},
        onOpenFilters: _noop,
        showComposer: false,
        mode: ContentBlockMode.link,
        anchorId: _selected,
        checkboxSide: CheckboxSide.left,
      ),
    );

    return SafeArea(
      child: Column(children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Conectar elementos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: OrientationBuilder(
            builder: (ctx, o) => o == Orientation.portrait
                ? Column(children: [left, const Divider(height: 1), right])
                : Row(children: [left, const VerticalDivider(width: 1), right]),
          ),
        ),
      ]),
    );
  }
}
