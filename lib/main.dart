// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'app/state/app_state.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseUIAuth.configureProviders([
    GoogleProvider(
      clientId: const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'),
    ),
  ]);

  runApp(const Bootstrap());
}

class Bootstrap extends StatelessWidget {
  const Bootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CaosBox • beta',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const _Gate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _Gate extends StatelessWidget {
  const _Gate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (ctx, snap) {
        final user = snap.data;
        if (user == null) {
          return SignInScreen(
            providers: [GoogleProvider(clientId: const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'))],
            showAuthActionSwitch: false,
          );
        }
        return ChangeNotifierProvider(
          create: (_) => AppState(),
          child: CaosApp(uid: user.uid),
        );
      },
    );
  }
}
