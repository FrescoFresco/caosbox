import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart' as fui;
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart' as fuig;

const String _googleClientId = String.fromEnvironment(
  'GOOGLE_WEB_CLIENT_ID',
  defaultValue: '',
);

class AuthGate extends StatelessWidget {
  final Widget Function(BuildContext context, User user) builder;
  const AuthGate({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snap.data;
        if (user == null) {
          final providers = <fui.AuthProvider>[
            fuig.GoogleProvider(clientId: _googleClientId),
          ];
          return fui.SignInScreen(
            providers: providers,
            headerBuilder: (context, _, __) => const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Bienvenido a CaosBox',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            ),
          );
        }

        return builder(context, user);
      },
    );
  }
}
