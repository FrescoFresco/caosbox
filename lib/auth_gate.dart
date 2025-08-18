// lib/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';

typedef AppBuilder = Widget Function(BuildContext, User);

const _kGoogleClientId =
    '1087718443702-n9856kennjfbunkb0hc26gntrljhnsrs.apps.googleusercontent.com';

class AuthGate extends StatelessWidget {
  final AppBuilder builder;
  const AuthGate({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final providers = [
      GoogleProvider(clientId: _kGoogleClientId),
    ];

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (ctx, snap) {
        final user = snap.data;
        if (user != null) {
          return builder(ctx, user);
        }
        return SignInScreen(
          providers: providers,
          showTitle: false,
          headerBuilder: (context, constraints, _) => const Padding(
            padding: EdgeInsets.all(16),
            child: Text('CaosBox', style: TextStyle(fontSize: 24)),
          ),
        );
      },
    );
  }
}
