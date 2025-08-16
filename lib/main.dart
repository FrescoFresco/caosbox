import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';

// UI lista con botón de Google
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? visibleError;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.web);

    // Configurar proveedor Google
    final google = GoogleProvider(
      clientId:
          '1087718443702-n9856kennjfbunkb0hc26gntrljhnsrs.apps.googleusercontent.com',
    );
    FirebaseUIAuth.configureProviders([google]);

    runApp(const CaosApp());
    return;
  } catch (e, st) {
    debugPrint('Fallo Firebase init: $e\n$st');
    visibleError = '$e';
  }

  runApp(MaterialApp(
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Error iniciando CaosBox:\n$visibleError',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  ));
}

class CaosApp extends StatelessWidget {
  const CaosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CaosBox • beta',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const _Gate(),
    );
  }
}

class _Gate extends StatelessWidget {
  const _Gate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, snap) {
        final user = snap.data;
        if (user == null) {
          return SignInScreen(
            // 👇 ¡Sin const aquí!
            providers: [
              GoogleProvider(
                clientId:
                    '1087718443702-n9856kennjfbunkb0hc26gntrljhnsrs.apps.googleusercontent.com',
              ),
            ],
            headerBuilder: (_, __, ___) => const Padding(
              padding: EdgeInsets.only(top: 32.0),
              child: Text(
                'CaosBox • beta',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('CaosBox • beta'),
            actions: [
              IconButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                icon: const Icon(Icons.logout),
                tooltip: 'Salir',
              ),
            ],
          ),
          body: Center(
            child: Text('Hola, ${user.displayName ?? user.email ?? user.uid}!'),
          ),
        );
      },
    );
  }
}
