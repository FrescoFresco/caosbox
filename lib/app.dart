// lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/core/models/enums.dart';
import 'package:caosbox/data/fire_repo.dart';
import 'package:caosbox/ui/screens/home_screen.dart';

class CaosApp extends StatefulWidget {
  final String uid;
  const CaosApp({super.key, required this.uid});

  @override
  State<CaosApp> createState() => _CaosAppState();
}

class _CaosAppState extends State<CaosApp> {
  @override
  void initState() {
    super.initState();
    final st = context.read<AppState>();
    st.attachRepo(FireRepo(FirebaseFirestore.instance, widget.uid), widget.uid);
  }

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}
