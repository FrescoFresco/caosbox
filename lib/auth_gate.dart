// lib/auth_gate.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'app_shell.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<void> _signInWithGoogleWeb() async {
    final provider = GoogleAuthProvider();
    await FirebaseAuth.instance.signInWithPopup(provider);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        final user = snap.data;
        if (user == null) {
          return Scaffold(
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FlutterLogo(size: 56),
                        const SizedBox(height: 16),
                        const Text('Inicia sesión para continuar', style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          icon: const Icon(Icons.login),
                          label: const Text('Continuar con Google'),
                          onPressed: _signInWithGoogleWeb,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        return AppShell(uid: user.uid);
      },
    );
  }
}
