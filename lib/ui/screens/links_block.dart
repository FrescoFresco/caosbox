import 'package:flutter/material.dart';
import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/core/models/item.dart';
import 'package:caosbox/ui/screens/info_modal.dart';
import 'package:caosbox/ui/widgets/search_bar.dart' as cx;
import 'package:caosbox/ui/widgets/item_card.dart';
import 'package:caosbox/ui/widgets/chips_panel.dart';

class LinksBlock extends StatefulWidget{
  final AppState st; const LinksBlock({super.key, required this.st});
  @override State<LinksBlock> createState()=>_LinksBlockState();
}

class _LinksBlockState extends State<LinksBlock> with AutomaticKeepAliveClientMixin{
  final _l=FilterSet(), _r=FilterSet(); final _qL=TextEditingController(), _qR=TextEditingController();
  String? sel; @override bool get wantKeepAlive=>true;
  @override void dispose(){_l.dispose(); _r.dispose(); _qL.dispose(); _qR.dispose(); super.dispose();}

  bool _matchQuick(String q, Item it){
    final s=q.trim().toLowerCase(); if(s.isEmpty) return true;
    final src='${it.id} ${it.text} ${widget.st.note(it.id)}'.toLowerCase();
    return src.contains(s);
  }

  Widget _panel({required String title, required Widget searchRow, required Widget body})=>Padding(
    padding: const EdgeInsets.symmetric(horizontal:12),
    child: Column(children:[
      Padding(padding: const EdgeInsets.only(bottom:8), child: Align(alignment: Alignment.centerLeft, child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)))),
      searchRow, const SizedBox(height:8), Expanded(child: body),
    ]),
  );

  void _openFilters(FilterSet set){
    showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true, builder: (_)=>Padding(
      padding: const EdgeInsets.all(12), child: Column(mainAxisSize: MainAxisSize.min, children:[
        ChipsPanel(set:set, onUpdate: ()=>setState((){}), defaults: const {}),
        const SizedBox(height:12),
        Align(alignment: Alignment.centerRight, child: ElevatedButton(onPressed: ()=>Navigator.pop(context), child: const Text('Aplicar'))),
      ]),
    ));
  }

  @override Widget build(BuildContext c){
    super.build(c); final st=widget.st; final all=st.all;
    final li=FilterEngine.apply(all.where((e)=>_matchQuick(_qL.text,e)).toList(), st, _l);
    final baseR=all.where((i)=>i.id!=sel).toList();
    final ri=FilterEngine.apply(baseR.where((e)=>_matchQuick(_qR.text,e)).toList(), st, _r);

    final lb=ListView.builder(itemCount: li.length, itemBuilder: (_,i){
      final it=li[i]; final ck=sel==it.id;
      return ItemCard(it:it, st:st, ex:false, onT:(){}, onInfo:()=>showInfoModal(c,it,st),
        cbR:true, ck:ck, onTapCb:()=>setState(()=>sel=ck?null:it.id));
    });

    final rb=sel==null
      ? const Center(child: Text('Selecciona un elemento'))
      : ListView.builder(itemCount: ri.length, itemBuilder: (_,i){
          final it=ri[i], ck=st.links(sel!).contains(it.id);
          return ItemCard(it:it, st:st, ex:false, onT:(){}, onInfo:()=>showInfoModal(c,it,st),
            cbL:true, ck:ck, onTapCb:()=>setState(()=>st.toggleLink(sel!, it.id)));
        });

    return Column(children:[
      const Padding(padding: EdgeInsets.fromLTRB(12,12,12,8), child: Text('Conectar elementos', style: TextStyle(fontSize:18, fontWeight: FontWeight.bold))),
      Expanded(child: OrientationBuilder(builder:(ctx,o)=>o==Orientation.portrait
        ? Column(children:[
            Expanded(child:_panel(title:'Seleccionar:', searchRow: cx.SearchBar(controller:_qL, onChanged: (_)=>setState((){}), onOpenFilters: ()=>_openFilters(_l)), body: lb)),
            const Divider(height:1),
            Expanded(child:_panel(title:'Conectar con:', searchRow: cx.SearchBar(controller:_qR, onChanged: (_)=>setState((){}), onOpenFilters: ()=>_openFilters(_r)), body: rb)),
          ])
        : Row(children:[
            Expanded(child:_panel(title:'Seleccionar:', searchRow: cx.SearchBar(controller:_qL, onChanged: (_)=>setState((){}), onOpenFilters: ()=>_openFilters(_l)), body: lb)),
            const VerticalDivider(width:1),
            Expanded(child:_panel(title:'Conectar con:', searchRow: cx.SearchBar(controller:_qR, onChanged: (_)=>setState((){}), onOpenFilters: ()=>_openFilters(_r)), body: rb)),
          ]))),
    ]);
  }
}
