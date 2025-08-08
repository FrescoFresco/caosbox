import 'package:flutter/material.dart';
import 'package:caosbox/src/models/models.dart' as models;
import 'package:caosbox/src/utils/filter_engine.dart' as utils;
import 'package:caosbox/src/widgets/quick_add.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CaosBox',
      theme: ThemeData(useMaterial3: true),
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
  final models.AppState _state    = models.AppState();
  final utils.FilterSet _filter   = utils.FilterSet();

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ideas = utils.FilterEngine.apply(
      _state.items(models.ItemType.idea),
      _state,
      _filter,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('CaosBox')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            QuickAdd(type: models.ItemType.idea, st: _state),
            const SizedBox(height: 12),
            TextField(
              controller: _filter.text,
              decoration: const InputDecoration(
                hintText: 'Buscar…',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: ideas.length,
                itemBuilder: (_, i) => Card(
                  child: ListTile(
                    title: Text(ideas[i].text),
                    subtitle: Text(ideas[i].id),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
