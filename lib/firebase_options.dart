// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Solo soportamos Web en este proyecto
    if (kIsWeb) return web;
    // Fallback: si se intenta otro, igualmente devolvemos web
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyBbpkoc4YlqfuYyM2TYASidFMOpeN9v2e4",
    appId: "1:1087718443702:web:53c05e5ca672de14b5f417",
    projectId: "caosbox-ef75b",
    messagingSenderId: "1087718443702",
    authDomain: "caosbox-ef75b.firebaseapp.com",
    storageBucket: "caosbox-ef75b.firebasestorage.app",
    measurementId: "G-8C1RD6K5Q5",
  );
}

const bool kIsWeb = identical(0, 0.0);
