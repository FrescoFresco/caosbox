import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fauth;
import 'package:firebase_ui_auth/firebase_ui_auth.dart' as fui;

/// Lee el client id de Google (lo pasas con --dart-define=GOOGLE_WEB_CLIENT_ID=...)
const String _googleClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

/// Muestra la pantalla de login si no hay usuario; cuando hay usuario,
/// llama al `builder` para renderizar tu app.
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
          // Pantalla de login de FirebaseUI con Google
          return fui.SignInScreen(
            providers: [
              // FirebaseUI define su propio GoogleProvider
              fui.GoogleProvider(clientId: _googleClientId),
            ],
            headerBuilder: (context, constraints, _) {
              return const Padding(
                padding: EdgeInsets.only(top: 48.0),
                child: _CenteredText('Inicia sesión con Google para continuar'),
              );
            },
          );
        }

        // Autenticado
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
      body: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
