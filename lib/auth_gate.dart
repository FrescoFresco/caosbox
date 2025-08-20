// lib/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthGate extends StatefulWidget {
  final Widget Function(User user) builder;
  const AuthGate({super.key, required this.builder});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Stream<User?> get _auth$ => FirebaseAuth.instance.authStateChanges();

  Future<void> _signInWithGoogle() async {
    final provider = GoogleAuthProvider();
    try {
      // Primero intentamos popup (web friendly)
      await FirebaseAuth.instance.signInWithPopup(provider);
    } catch (_) {
      // Fallback a redirect si el popup falla (bloqueo cookies/ventanas, etc.)
      await FirebaseAuth.instance.signInWithRedirect(provider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth$,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snap.data;
        if (user == null) {
          return Scaffold(
            body: Center(
              child: FilledButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Entrar con Google'),
                onPressed: _signInWithGoogle,
              ),
            ),
          );
        }
        return widget.builder(user);
      },
    );
  }
}
