import 'package:flutter/material.dart';
import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/ui/widgets/relation_picker.dart';

class LinksBlock extends StatelessWidget {
  final AppState state;
  const LinksBlock({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Conectar elementos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        const Divider(height: 1),
        Expanded(child: RelationPicker(state: state, twoPane: true)),
      ]),
    );
  }
}
