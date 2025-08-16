import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final google = GoogleProvider(
    clientId: const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'),
  );

  runApp(CaosGate(google: google));
}

class CaosGate extends StatelessWidget {
  const CaosGate({super.key, required this.google});
  final GoogleProvider google;

  @override
  Widget build(BuildContext context) {
    final signedIn = FirebaseAuth.instance.currentUser != null;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: signedIn ? '/' : '/sign-in',
      routes: {
        '/sign-in': (ctx) => SignInScreen(
              providers: [google],
              headerBuilder: (ctx, _, __) => const Padding(
                padding: EdgeInsets.all(16),
                child: Text('CaosBox • beta', style: TextStyle(fontSize: 20)),
              ),
              actions: [
                AuthStateChangeAction<SignedIn>((context, state) {
                  Navigator.pushReplacementNamed(context, '/');
                }),
              ],
            ),
        '/': (ctx) => const CaosApp(),
      },
    );
  }
}
