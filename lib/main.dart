import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// === Config de Firebase desde secrets (GitHub Actions) ===
/// OJO: las claves llegan por --dart-define en el build.yml.
/// Las constantes con clave LITERAL funcionan en compilación.
const _apiKey            = String.fromEnvironment('FB_API_KEY', defaultValue: '');
const _appId             = String.fromEnvironment('FB_APP_ID', defaultValue: '');
const _projectId         = String.fromEnvironment('FB_PROJECT_ID', defaultValue: '');
const _messagingSenderId = String.fromEnvironment('FB_MESSAGING_SENDER_ID', defaultValue: '');
const _authDomain        = String.fromEnvironment('FB_AUTH_DOMAIN', defaultValue: '');
const _storageBucket     = String.fromEnvironment('FB_STORAGE_BUCKET', defaultValue: '');
const _measurementId     = String.fromEnvironment('FB_MEASUREMENT_ID', defaultValue: '');
const _googleClientId    = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase con opciones explícitas (nos saltamos cualquier archivo previo).
  final options = FirebaseOptions(
    apiKey: _apiKey,
    appId: _appId,
    projectId: _projectId,
    messagingSenderId: _messagingSenderId,
    authDomain: _authDomain.isEmpty ? null : _authDomain,
    storageBucket: _storageBucket.isEmpty ? null : _storageBucket,
    measurementId: _measurementId.isEmpty ? null : _measurementId,
  );

  await Firebase.initializeApp(options: options);

  // Logs útiles en modo web
  if (kIsWeb) {
    // ignore: avoid_print
    print('== Firebase WEB == projectId=$_projectId | authDomain=$_authDomain | clientId=$_googleClientId');
  }

  runApp(const CaosApp());
}

class CaosApp extends StatelessWidget {
  const CaosApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CaosBox • beta',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF8B5CF6),
        scaffoldBackgroundColor: const Color(0xFFF6F3FF),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _CenterText('Cargando CaosBox...');
        }
        final user = snap.data;
        if (user == null) {
          return const SignInScreen();
        }
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
  bool _working = false;
  String? _error;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final auth = FirebaseAuth.instance;

      if (kIsWeb) {
        // En web usamos popup; si el navegador lo bloquea, probamos redirect.
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..setCustomParameters(<String, String>{
            if (_googleClientId.isNotEmpty) 'client_id': _googleClientId,
            'prompt': 'select_account'
          });

        try {
          await auth.signInWithPopup(provider);
        } catch (e) {
          // fallback a redirect
          await auth.signInWithRedirect(provider);
        }
      } else {
        // (para no-web, por si compilas móvil en el futuro)
        final provider = GoogleAuthProvider();
        await auth.signInWithProvider(provider);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CaosBox • beta')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _CenterText('Inicia sesión con Google para continuar'),
              const SizedBox(height: 16),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              FilledButton.icon(
                onPressed: _working ? null : _signInWithGoogle,
                icon: const Icon(Icons.login),
                label: Text(_working ? 'Abriendo Google...' : 'Continuar con Google'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Si aparece bloqueado el pop-up, permite las ventanas emergentes\n'
                'o vuelve a intentarlo (hará redirect).',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CaosBox • beta'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: Center(
        child: Text('Hola, ${user.displayName ?? user.email ?? 'usuario'}!',
            style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}

class _CenterText extends StatelessWidget {
  final String text;
  const _CenterText(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text, textAlign: TextAlign.center);
  }
}
