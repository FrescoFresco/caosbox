import 'package:flutter/material.dart';
import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/core/models/item.dart';
import 'package:caosbox/ui/widgets/search_bar.dart' as cx;
import 'package:caosbox/ui/widgets/chips_panel.dart';
import 'package:caosbox/ui/widgets/item_card.dart';
import 'package:caosbox/ui/screens/info_modal.dart';

class LinksBlock extends StatefulWidget {
  final AppState st;
  const LinksBlock({super.key, required this.st});
  @override State<LinksBlock> createState()=>_LinksBlockState();
}

class _LinksBlockState extends State<LinksBlock> with AutomaticKeepAliveClientMixin {
  final _lq = TextEditingController(); final _rq = TextEditingController();
  final _l = FilterSet(); final _r = FilterSet();
  String? sel;
  @override void dispose(){_lq.dispose(); _rq.dispose(); _l.dispose(); _r.dispose(); super.dispose();}
  void _rS()=>setState((){});
  @override bool get wantKeepAlive=>true;

  void _openFiltersLeft(){
    showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true, builder: (_)=>Padding(
      padding: const EdgeInsets.all(12),
      child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ChipsPanel(set:_l, onUpdate:_rS, defaults: const {}),
        const SizedBox(height: 12),
        Align(alignment: Alignment.centerRight, child: ElevatedButton(onPressed: ()=>Navigator.pop(context), child: const Text('Aplicar'))),
      ])),
    ));
  }
  void _openFiltersRight(){
    showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true, builder: (_)=>Padding(
      padding: const EdgeInsets.all(12),
      child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ChipsPanel(set:_r, onUpdate:_rS, defaults: const {}),
        const SizedBox(height: 12),
        Align(alignment: Alignment.centerRight, child: ElevatedButton(onPressed: ()=>Navigator.pop(context), child: const Text('Aplicar'))),
      ])),
    ));
  }

  @override Widget build(BuildContext c){
    super.build(c);
    final st = widget.st;

    List<Item> all = st.all;

    List<Item> li = all.where((it){
      final q=_lq.text.trim().toLowerCase(); if(q.isEmpty) return true;
      final src='${it.id} ${it.text} ${st.note(it.id)}'.toLowerCase();
      return src.contains(q);
    }).toList();
    li = FilterEngine.apply(li, st, _l);

    final baseRight = sel == null ? <Item>[] : all.where((i)=> i.id != sel).toList();
    List<Item> ri = baseRight.where((it){
      final q=_rq.text.trim().toLowerCase(); if(q.isEmpty) return true;
      final src='${it.id} ${it.text} ${st.note(it.id)}'.toLowerCase();
      return src.contains(q);
    }).toList();
    ri = FilterEngine.apply(ri, st, _r);

    Widget leftList() => ListView.builder(
      itemCount: li.length,
      itemBuilder: (_,i){
        final it = li[i];
        return ItemCard(
          it: it, st: st, ex: false,
          onT: (){}, onInfo: ()=>showInfoModal(context, it, st),
          cbR: true, ck: sel==it.id,
          onTapCb: ()=> setState(()=> sel = sel==it.id ? null : it.id),
        );
      },
    );

    Widget rightList() {
      if (sel == null) return const Center(child: Text('Selecciona un elemento'));
      return ListView.builder(
        itemCount: ri.length,
        itemBuilder: (_,i){
          final it = ri[i];
          final ck = st.links(sel!).contains(it.id);
          return ItemCard(
            it: it, st: st, ex: false,
            onT: (){}, onInfo: ()=>showInfoModal(context, it, st),
            cbL: true, ck: ck,
            onTapCb: ()=> setState(()=> st.toggleLink(sel!, it.id)),
          );
        },
      );
    }

    return Column(children:[
      const Padding(
        padding: EdgeInsets.fromLTRB(12,12,12,8),
        child: Text('Conectar elementos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      Expanded(child: OrientationBuilder(builder:(ctx,o)=> o==Orientation.portrait
        ? Column(children:[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: cx.SearchBar(controller:_lq, onChanged: (_)=>_rS(), onOpenFilters: _openFiltersLeft, hint:'Buscar…'),
            ),
            const SizedBox(height: 8),
            Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: leftList())),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: cx.SearchBar(controller:_rq, onChanged: (_)=>_rS(), onOpenFilters: _openFiltersRight, hint:'Conectar con…'),
            ),
            Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: rightList())),
          ])
        : Row(children:[
            Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(children:[
                cx.SearchBar(controller:_lq, onChanged: (_)=>_rS(), onOpenFilters: _openFiltersLeft, hint:'Buscar…'),
                const SizedBox(height: 8),
                Expanded(child: leftList()),
              ]),
            )),
            const VerticalDivider(width: 1),
            Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(children:[
                cx.SearchBar(controller:_rq, onChanged: (_)=>_rS(), onOpenFilters: _openFiltersRight, hint:'Conectar con…'),
                const SizedBox(height: 8),
                Expanded(child: rightList()),
              ]),
            )),
          ]))),
    ]);
  }
}
