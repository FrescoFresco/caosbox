import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../models/item.dart';
import 'info_modal.dart';

class LinksBlock extends StatefulWidget {
  final AppState st;
  const LinksBlock({super.key, required this.st});
  @override State<LinksBlock> createState() => _LinksBlockState();
}

class _LinksBlockState extends State<LinksBlock> with AutomaticKeepAliveClientMixin {
  String? sel;
  @override bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext c) {
    super.build(c);
    final st = widget.st;
    final all = st.all;

    Widget list(List<Item> src, {required bool right}) => ListView.builder(
      itemCount: src.length,
      itemBuilder: (_, i) {
        final it = src[i];
        final ck = right && sel != null ? st.links(sel!).contains(it.id) : (sel == it.id);
        return CheckboxListTile(
          value: ck,
          onChanged: (_) {
            setState(() {
              if (!right) {
                sel = sel == it.id ? null : it.id;
              } else if (sel != null) {
                st.toggleLink(sel!, it.id);
              }
            });
          },
          title: Text('${it.id} — ${it.text}', maxLines: 1, overflow: TextOverflow.ellipsis),
          controlAffinity: ListTileControlAffinity.leading,
          secondary: IconButton(icon: const Icon(Icons.info_outline), onPressed: () => showInfoModal(c, it, st)),
        );
      },
    );

    final left = list(all, right: false);
    final rightList = sel == null ? const Center(child: Text('Selecciona un elemento')) : list(all.where((x) => x.id != sel).toList(), right: true);

    return Column(children: [
      const Padding(padding: EdgeInsets.fromLTRB(12, 12, 12, 8), child: Text('Conectar elementos', style: TextStyle(fontWeight: FontWeight.bold))),
      Expanded(
        child: Row(children: [
          Expanded(child: Column(children: [
            const Padding(padding: EdgeInsets.only(left: 12, bottom: 8), child: Align(alignment: Alignment.centerLeft, child: Text('Seleccionar:'))),
            Expanded(child: left),
          ])),
          const VerticalDivider(width: 1),
          Expanded(child: Column(children: [
            const Padding(padding: EdgeInsets.only(left: 12, bottom: 8), child: Align(alignment: Alignment.centerLeft, child: Text('Conectar con:'))),
            Expanded(child: rightList),
          ])),
        ]),
      ),
    ]);
  }
}
