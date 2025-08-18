// lib/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fauth;
import 'package:firebase_ui_auth/firebase_ui_auth.dart' as fui;
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart' as fuig;

const String _googleClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

class AuthGate extends StatelessWidget {
  final Widget Function(BuildContext, fauth.User) builder;

  const AuthGate({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<fauth.User?>(
      stream: fauth.FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _CenteredText('Cargando CaosBox...');
        }

        final user = snapshot.data;
        if (user == null) {
          return fui.SignInScreen(
            providers: [
              fuig.GoogleProvider(clientId: _googleClientId),
            ],
            headerBuilder: (context, constraints, _) => const Padding(
              padding: EdgeInsets.only(top: 48),
              child: _CenteredText('Inicia sesión con Google para continuar'),
            ),
          );
        }

        return builder(context, user);
      },
    );
  }
}

class _CenteredText extends StatelessWidget {
  final String text;
  const _CenteredText(this.text);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
    );
  }
}
