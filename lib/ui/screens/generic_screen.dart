import 'package:flutter/material.dart';
import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/config/blocks.dart';
import 'package:caosbox/core/models/enums.dart';
import 'package:caosbox/domain/search/search_models.dart';
import 'package:caosbox/ui/widgets/content_block.dart';

class GenericScreen extends StatefulWidget{
  final Block b; final AppState st;
  const GenericScreen({super.key, required this.b, required this.st});
  @override State<GenericScreen> createState()=>_GenericScreenState();
}

class _GenericScreenState extends State<GenericScreen> with AutomaticKeepAliveClientMixin{
  String _quick = '';
  SearchSpec _spec = const SearchSpec();
  @override bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext ctx){
    super.build(ctx);
    final t = widget.b.type!;
    return Padding(
      padding: const EdgeInsets.all(0),
      child: ContentBlock(
        state: widget.st,
        types: {t},
        spec: _spec,
        quickQuery: _quick,
        onQuickQuery: (q)=> setState(()=> _quick = q),
        onSpecChanged: (s)=> setState(()=> _spec = s),
        showComposer: true,
        mode: ContentBlockMode.list,
        checkboxSide: CheckboxSide.none,
      ),
    );
  }
}
