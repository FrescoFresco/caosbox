import 'package:flutter/material.dart';
import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/core/models/item.dart';
import 'package:caosbox/config/blocks.dart';
import 'package:caosbox/ui/widgets/search_bar.dart' as cx;
import 'package:caosbox/ui/widgets/chips_panel.dart';
import 'package:caosbox/ui/widgets/item_card.dart';
import 'package:caosbox/ui/screens/info_modal.dart';

class GenericScreen extends StatefulWidget {
  final Block block; final AppState st;
  const GenericScreen({super.key, required this.block, required this.st});
  @override State<GenericScreen> createState()=>_GenericScreenState();
}

class _GenericScreenState extends State<GenericScreen> with AutomaticKeepAliveClientMixin {
  late final TextEditingController _quick;
  final _filters=FilterSet(); final _expanded=<String>{};
  void _r()=>setState((){});
  @override bool get wantKeepAlive=>true;

  @override void initState(){super.initState(); _quick=TextEditingController();}
  @override void dispose(){_quick.dispose(); _filters.dispose(); super.dispose();}

  void _openFilters(){
    showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true, builder: (_)=>Padding(
      padding: const EdgeInsets.all(12),
      child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ChipsPanel(set:_filters, onUpdate:_r, defaults: const {}),
        const SizedBox(height: 12),
        Align(alignment: Alignment.centerRight, child: ElevatedButton(onPressed: ()=>Navigator.pop(context), child: const Text('Aplicar'))),
      ])),
    ));
  }

  @override Widget build(BuildContext ctx){
    super.build(ctx);
    final t=widget.block.type!; final items=widget.st.items(t);

    List<Item> filtered=items.where((it){
      final q=_quick.text.trim().toLowerCase(); if(q.isEmpty) return true;
      final src='${it.id} ${it.text} ${widget.st.note(it.id)}'.toLowerCase();
      return src.contains(q);
    }).toList();

    filtered = FilterEngine.apply(filtered, widget.st, _filters);

    return Padding(padding: const EdgeInsets.all(12), child: Column(children: [
      cx.SearchBar(controller:_quick, onChanged: (_)=>_r(), onOpenFilters: _openFilters, hint:'Buscar…'),
      const SizedBox(height:8),
      Expanded(child: ListView.builder(itemCount: filtered.length, itemBuilder: (_,i){
        final it=filtered[i], open=_expanded.contains(it.id);
        return ItemCard(it:it, st:widget.st, ex:open, onT: (){
          if(open){_expanded.remove(it.id);} else {_expanded.add(it.id);} _r();
        }, onInfo: ()=>showInfoModal(context, it, widget.st));
      })),
    ]));
  }
}
