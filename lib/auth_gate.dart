// lib/auth_gate.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'app_home.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final providers = [
      GoogleProvider(
        // NO uses const en GoogleProvider; y lee el clientId del --dart-define
        clientId: const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: ''),
      ),
    ];

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        final user = snap.data;
        if (user == null) {
          return SignInScreen(
            providers: providers,
            showAuthActionSwitch: false,
            headerBuilder: (context, constraints, shrinkOffset) =>
                const SizedBox(height: 24),
          );
        }
        return const AppHome();
      },
    );
  }
}
