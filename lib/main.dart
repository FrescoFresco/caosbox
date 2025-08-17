import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const CaosApp());
}

class CaosApp extends StatelessWidget {
  const CaosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CaosBox • beta',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const Gate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// “Puerta” de la app: o login o home.
class Gate extends StatelessWidget {
  const Gate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, snap) {
        final user = snap.data;
        if (user == null) return const SignInScreen();
        return HomeScreen(user: user);
      },
    );
  }
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _login() async {
    setState(() { _busy = true; _error = null; });
    try {
      // Web: popup directo sin librerías extra
      final cred = await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
      final u = cred.user;
      if (u != null) {
        // Crea/actualiza perfil mínimo en Firestore
        final doc = FirebaseFirestore.instance.collection('users').doc(u.uid);
        await doc.set({
          'uid': u.uid,
          'name': u.displayName,
          'email': u.email,
          'photo': u.photoURL,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      // Fallback si el popup lo bloquea: redirect
      try {
        await FirebaseAuth.instance.signInWithRedirect(GoogleAuthProvider());
      } catch (e2) {
        setState(() { _error = '$e'; });
      }
    } finally {
      if (mounted) setState(() { _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('CaosBox • beta', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _busy ? null : _login,
                icon: const Icon(Icons.login),
                label: Text(_busy ? 'Entrando...' : 'Entrar con Google'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CaosBox • beta'),
        actions: [
          IconButton(
            tooltip: 'Salir',
            onPressed: () async => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (_, snap) {
            final name = user.displayName ?? 'usuario';
            if (snap.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            return Text('Hola, $name!', style: const TextStyle(fontSize: 18));
          },
        ),
      ),
    );
  }
}
