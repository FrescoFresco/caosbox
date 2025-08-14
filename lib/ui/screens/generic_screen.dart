import 'package:flutter/material.dart';

import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/core/models/enums.dart';
import 'package:caosbox/core/models/item.dart';
import 'package:caosbox/config/blocks.dart';

import 'package:caosbox/ui/widgets/search_bar.dart' as cx; // <— buscador modular
import 'package:caosbox/ui/widgets/composer_card.dart';
import 'package:caosbox/ui/widgets/chips_panel.dart';
import 'package:caosbox/ui/widgets/item_card.dart';
import 'package:caosbox/ui/screens/info_modal.dart';

class GenericScreen extends StatefulWidget {
  final Block block;
  final AppState st;
  const GenericScreen({super.key, required this.block, required this.st});

  @override
  State<GenericScreen> createState() => _GenericScreenState();
}

class _GenericScreenState extends State<GenericScreen>
    with AutomaticKeepAliveClientMixin {
  late final TextEditingController _compose;
  late final TextEditingController _quick; // <— texto de búsqueda rápida
  final _filters = FilterSet();             // <— tus filtros avanzados
  final _expanded = <String>{};

  @override
  void initState() {
    super.initState();
    _compose = TextEditingController();
    _quick = TextEditingController();
    if (widget.block.defaults.isNotEmpty) {
      _filters.setDefaults(widget.block.defaults);
    }
  }

  @override
  void dispose() {
    _compose.dispose();
    _quick.dispose();
    _filters.dispose();
    super.dispose();
  }

  void _r() => setState(() {});
  @override
  bool get wantKeepAlive => true;

  void _openFilters() {
    // mismo modal de filtros que ya usabas (ChipsPanel)
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(12),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ChipsPanel(
                set: _filters,
                onUpdate: () {
                  _r();
                },
                defaults: widget.block.defaults,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _r();
                  },
                  child: const Text('Aplicar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    super.build(ctx);

    final t = widget.block.type!;
    final cfg = widget.block.cfg!;
    final items = widget.st.items(t);

    // quick filter (id+texto+nota) + avanzados (FilterEngine)
    List<Item> filtered = items.where((it) {
      final q = _quick.text.trim().toLowerCase();
      if (q.isNotEmpty) {
        final src =
            '${it.id} ${it.text} ${widget.st.note(it.id)}'.toLowerCase();
        if (!src.contains(q)) return false;
      }
      return true;
    }).toList();

    filtered = FilterEngine.apply(filtered, widget.st, _filters);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Composer de alta (igual que antes)
          ComposerCard(
            icon: cfg.icon,
            hint: cfg.hint,
            c: _compose,
            onAdd: () {
              widget.st.add(t, _compose.text);
              _compose.clear();
              _r();
            },
            onCancel: () {
              _compose.clear();
              _r();
            },
          ),

          const SizedBox(height: 12),

          // === Buscador modular: input + botón filtros ===
          cx.SearchBar(
            controller: _quick,
            onChanged: (_) => _r(),
            onOpenFilters: _openFilters,
            hint: 'Buscar…',
          ),

          const SizedBox(height: 8),

          // (opcional) indicador de filtros activos
          if (_filters.hasActive)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Filtros activos',
                style:
                    Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.blueGrey),
              ),
            ),

          const SizedBox(height: 8),

          // Lista
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final it = filtered[i];
                final open = _expanded.contains(it.id);
                return ItemCard(
                  it: it,
                  st: widget.st,
                  ex: open,
                  onT: () {
                    if (open) {
                      _expanded.remove(it.id);
                    } else {
                      _expanded.add(it.id);
                    }
                    _r();
                  },
                  onInfo: () => showInfoModal(context, it, widget.st),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
