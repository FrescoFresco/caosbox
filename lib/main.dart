// lib/main.dart
import 'package:flutter/material.dart';
import 'package:caosbox/app.dart';

void main() => runApp(const CaosRoot());

class CaosRoot extends StatelessWidget {
  const CaosRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CaosBox • beta',
      theme: ThemeData(useMaterial3: true),
      home: const CaosBox(),
    );
  }
}
