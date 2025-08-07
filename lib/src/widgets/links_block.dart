import 'package:flutter/material.dart';
import '../models/models.dart' as models;
import 'item_card.dart';
import 'info_modal.dart';

class LinksBlock extends StatefulWidget {
  final models.AppState st;
  const LinksBlock({super.key, required this.st});
  @override State<LinksBlock> createState() => _LinksBlockState();
}

class _LinksBlockState extends State<LinksBlock> {
  String? _sel;
  @override Widget build(BuildContext ctx) {
    final left  = widget.st.items(models.ItemType.idea)+widget.st.items(models.ItemType.action);
    final right = left.where((e) => e.id!=_sel).toList();
    return Row(children:[
      Expanded(child:_buildList(left, true)),
      const VerticalDivider(width:1),
      Expanded(child:_sel==null?const Center(child:Text('Selecciona')):_buildList(right,false)),
    ]);
  }
  Widget _buildList(List<models.Item> items, bool left) => ListView(
    children:items.map((it)=>ItemCard(
      it:it, st:widget.st,
      onInfo: ()=>showInfoModal(context,it,widget.st),
      )).toList());
}
