import 'package:flutter/material.dart';
import '../../config/blocks.dart';
import '../../models/enums.dart';
import '../../state/app_state.dart';
import '../../ui/widgets/item_card.dart';
import 'info_modal.dart';

// NUEVO: motor de búsqueda
import '../../search/search_models.dart';
import '../../search/search_engine.dart';

class GenericScreen extends StatefulWidget {
  final Block block;
  final AppState state;
  final SearchSpec spec; // <<— NUEVO
  const GenericScreen({super.key, required this.block, required this.state, required this.spec});

  @override State<GenericScreen> createState() => _GenericScreenState();
}

class _GenericScreenState extends State<GenericScreen>
    with AutomaticKeepAliveClientMixin {
  final _ex = <String>{};
  @override bool get wantKeepAlive => true;

  @override Widget build(BuildContext ctx) {
    super.build(ctx);
    final t   = widget.block.type!;
    final src = widget.state.items(t);

    // Aplica búsqueda global (spec)
    final filtered = applySearch(widget.state, src, widget.spec);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        Expanded(
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final it   = filtered[i];
              final open = _ex.contains(it.id);
              return ItemCard(
                item: it,
                st: widget.state,
                ex: open,
                onT: () {
                  open ? _ex.remove(it.id) : _ex.add(it.id);
                  setState((){});
                },
                onInfo: () => showInfoModal(ctx, it, widget.state),
              );
            },
          ),
        ),
      ]),
    );
  }
}
