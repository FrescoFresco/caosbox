import 'package:flutter/material.dart';
import 'ui/screens/tab_b1.dart';
import 'ui/screens/tab_b2.dart';
import 'ui/screens/tab_links.dart';

class CaosApp extends StatelessWidget {
  final bool demoBanner;
  const CaosApp({super.key, this.demoBanner = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('CaosBox'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'B1'),
                Tab(text: 'B2'),
                Tab(text: 'Enlaces'),
              ],
            ),
          ),
          body: Stack(
            children: [
              const TabBarView(
                children: [TabB1(), TabB2(), TabLinks()],
              ),
              if (demoBanner)
                const Positioned(
                  right: 12,
                  bottom: 12,
                  child: _DemoBanner(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoBanner extends StatelessWidget {
  const _DemoBanner();
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text('DEMO local', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
