
import 'package:flutter/material.dart';
import '../../config/blocks.dart';
import '../../models/enums.dart';
import '../../state/app_state.dart';
import '../../ui/widgets/composer_card.dart';
import '../../ui/widgets/chips_panel.dart';
import '../../ui/widgets/item_card.dart';
import 'info_modal.dart';

class GenericScreen extends StatefulWidget {
  final Block block;
  final AppState state;
  const GenericScreen({super.key, required this.block, required this.state});

  @override State<GenericScreen> createState() => _GenericScreenState();
}

class _GenericScreenState extends State<GenericScreen>
    with AutomaticKeepAliveClientMixin {
  late final TextEditingController _c;
  final _f = FilterSet();
  final _ex = <String>{};

  @override void initState() { super.initState(); _c = TextEditingController(); }
  @override void dispose() { _c.dispose(); _f.dispose(); super.dispose(); }
  void _r() => setState(() {});
  @override bool get wantKeepAlive => true;

  @override Widget build(BuildContext ctx) {
    super.build(ctx);
    final t   = widget.block.type!;
    final cfg = widget.block.cfg!;
    final items = widget.state.items(t);

    final filtered = items.where((it) {
      final q = _f.text.text.toLowerCase();
      if (q.isNotEmpty && !('${it.id} ${it.text}'.toLowerCase().contains(q)))
        return false;

      bool pass(FilterKey k, bool v) => switch (_f.modes[k]!) {
            FilterMode.off     => true,
            FilterMode.include => v,
            FilterMode.exclude => !v,
          };

      return pass(FilterKey.completed, it.status == ItemStatus.completed) &&
          pass(FilterKey.archived,  it.status == ItemStatus.archived) &&
          pass(FilterKey.hasLinks, widget.state.links(it.id).isNotEmpty);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        ComposerCard(
          icon: cfg.icon,
          hint: cfg.hint,
          c: _c,
          onAdd: () { widget.state.add(t, _c.text); _c.clear(); _r(); },
          onCancel: () { _c.clear(); _r(); },
        ),
        const SizedBox(height: 12),
        ChipsPanel(set: _f, onUpdate: _r),
        const SizedBox(height: 8),
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
                  _r();
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
