import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';

// UI lista de Firebase
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';

// TODO: importa tu app real
import 'app.dart'; // debe exponer CaosApp()

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configuramos el proveedor de Google (usa el client_id Web)
  FirebaseUIAuth.configureProviders([
    GoogleProvider(
      clientId: const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: ''),
    ),
  ]);

  runApp(const _Root());
}

class _Root extends StatelessWidget {
  const _Root({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CaosBox • beta',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          final user = snap.data;
          if (user == null) {
            // Pantalla de login de Firebase UI (muy pocas líneas)
            return SignInScreen(
              providers: const [GoogleProvider(clientId: String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: ''))],
              headerBuilder: (_, __, ___) => const Padding(
                padding: EdgeInsets.only(top: 48, bottom: 16),
                child: Center(child: Text('CaosBox • beta', style: TextStyle(fontSize: 22))),
              ),
            );
          }
          // Ya autenticado -> tu app
          return const CaosApp();
        },
      ),
    );
  }
}
