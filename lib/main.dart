import 'dart:async';
import 'package:flutter/material.dart';
import 'package:caosbox/app.dart';

void main() {
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
  };
  runZonedGuarded(() {
    runApp(const CaosApp());
  }, (e, st) {
    // En Web verás el error en DevTools > Console
    // ignore: avoid_print
    print('Zoned error: $e\n$st');
  });
}
