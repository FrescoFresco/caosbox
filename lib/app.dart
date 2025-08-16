import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/data/fire_repo.dart';

import 'package:caosbox/config/blocks.dart';
import 'package:caosbox/ui/screens/generic_screen.dart';
import 'package:caosbox/ui/screens/links_block.dart';

class CaosApp extends StatefulWidget {
  const CaosApp({super.key});
  @override State<CaosApp> createState() => _CaosAppState();
}

class _CaosAppState extends State<CaosApp> {
  late final AppState st;

  @override
  void initState() {
    super.initState();
    st = AppState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    st.attachRepo(FireRepo(FirebaseFirestore.instance, uid));
  }

  @override
  void dispose() { st.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: st,
      builder: (_, __) => DefaultTabController(
        length: blocks.length,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('CaosBox • beta'),
            bottom: TabBar(
              tabs: [for (final b in blocks) Tab(icon: Icon(b.icon), text: b.label)],
            ),
          ),
          body: SafeArea(
            child: TabBarView(
              children: [
                for (final b in blocks)
                  b.type != null
                    ? GenericScreen(block: b, st: st)
                    : LinksBlock(st: st),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
