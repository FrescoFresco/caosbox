// lib/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fauth;
import 'package:firebase_ui_auth/firebase_ui_auth.dart' as fui;
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';

class AuthGate extends StatelessWidget {
  final Widget Function(BuildContext, fauth.User) builder;
  const AuthGate({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final providers = <fui.AuthProvider>[
      GoogleProvider(
        clientId: const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: ''),
      ),
    ];

    return StreamBuilder<fauth.User?>(
      stream: fauth.FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.active) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snap.data;
        if (user == null) {
          return fui.SignInScreen(
            providers: providers,
            showAuthActionSwitch: false,
          );
        }
        return builder(context, user);
      },
    );
  }
}
