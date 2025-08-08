import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:caosbox/src/models/models.dart'   as models;
import 'package:caosbox/src/widgets/quick_add.dart';
import 'package:caosbox/src/widgets/chips_panel.dart';
import 'package:caosbox/src/widgets/item_card.dart';
import 'package:caosbox/src/utils/filter_engine.dart' as utils;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CaosBox',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: const CaosBox(),
    );
  }
}

class CaosBox extends StatefulWidget {
  const CaosBox({super.key});
  @override
  State<CaosBox> createState() => _CaosBoxState();
}

class _CaosBoxState extends State<CaosBox> {
  final models.AppState _state   = models.AppState();
  final utils.FilterSet _filter  = utils.FilterSet();
  final Set<String>     _expand  = <String>{};

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final items = utils.FilterEngine.apply(
      _state.items(models.ItemType.idea),
      _state,
      _filter,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('CaosBox')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            QuickAdd(
              type   : models.ItemType.idea,
              st     : _state,
              onAdded: _refresh,
            ),
            const SizedBox(height: 12),
            ChipsPanel(set: _filter, onUpdate: _refresh),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: items.map((it) {
                  final open = _expand.contains(it.id);
                  return ItemCard(
                    it         : it,
                    st         : _state,
                    isExpanded : open,
                    onTapBody  : () {
                      setState(() => open
                          ? _expand.remove(it.id)
                          : _expand.add(it.id));
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
