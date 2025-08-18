// lib/auth_gate.dart
import 'package:flutter/material.dart';

// IMPORTS con prefijo para evitar choques de nombres:
import 'package:firebase_auth/firebase_auth.dart' as fauth show FirebaseAuth, User;
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart'
    as fapi show AuthCredential;

import 'package:firebase_ui_auth/firebase_ui_auth.dart' as fui;
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart' as fuig;

/// Puerta de autenticación muy simple:
/// - Si hay usuario -> muestra tu app (builder)
/// - Si no hay usuario -> muestra pantalla de login de Firebase UI (Google)
class AuthGate extends StatelessWidget {
  final Widget Function(BuildContext context, fauth.User user) builder;

  const AuthGate({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<fauth.User?>(
      stream: fauth.FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        final user = snap.data;
        if (user != null) {
          return builder(context, user);
        }

        // Tu Client ID de OAuth (lo pasamos por --dart-define)
        final clientId = const String.fromEnvironment(
          'GOOGLE_WEB_CLIENT_ID',
          defaultValue: '',
        );

        // IMPORTANTE: tipamos la lista con la clase de firebase_ui_auth
        final List<fui.AuthProvider<fui.AuthListener, fapi.AuthCredential>> providers = [
          fuig.GoogleProvider(clientId: clientId),
        ];

        return fui.SignInScreen(
          providers: providers,
          // Opcional: comportamiento al autenticar
          actions: [
            fui.AuthStateChangeAction<fui.SignedIn>((context, state) {
              // ya estás dentro; FirebaseUI cerrará la pantalla
            }),
          ],
        );
      },
    );
  }
}
