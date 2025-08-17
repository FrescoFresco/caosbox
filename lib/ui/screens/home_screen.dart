// lib/ui/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/core/models/enums.dart';
import 'package:caosbox/ui/screens/items_screen.dart';
import 'package:caosbox/ui/screens/links_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final TabController _tc;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('CaosBox • beta'),
        bottom: TabBar(
          controller: _tc,
          tabs: const [
            Tab(text: 'B1 (Ideas)'),
            Tab(text: 'B2 (Acciones)'),
            Tab(text: 'Enlaces'),
          ],
        ),
      ),
      body: st.loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tc,
              children: const [
                ItemsScreen(type: ItemType.idea),
                ItemsScreen(type: ItemType.action),
                LinksScreen(),
              ],
            ),
    );
  }
}
