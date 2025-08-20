import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart' as fui;

import 'data/repo.dart';
import 'data/fire_repo_firestore.dart';
import 'data/in_memory_repo.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool firebaseOk = false;
  try { await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform); firebaseOk = true; } catch (_) {}
  runApp(CaosRoot(firebaseOk: firebaseOk));
}

class CaosRoot extends StatelessWidget {
  final bool firebaseOk;
  const CaosRoot({super.key, required this.firebaseOk});

  @override
  Widget build(BuildContext context) {
    if (!firebaseOk) {
      final repo = InMemoryRepo.seed();
      return MultiProvider(
        providers: [Provider<Repo>.value(value: repo), ChangeNotifierProvider(create: (_) => AppState(repo))],
        child: const CaosApp(demoBanner: true),
      );
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, s) {
          if (s.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
          if (s.data == null) return fui.SignInScreen(providers: [fui.EmailAuthProvider()]);
          final repo = FireRepoFirestore();
          return MultiProvider(
            providers: [Provider<Repo>.value(value: repo), ChangeNotifierProvider(create: (_) => AppState(repo))],
            child: const CaosApp(),
          );
        },
      ),
    );
  }
}
