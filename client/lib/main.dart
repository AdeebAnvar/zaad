import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pos/app/desktop_exit_hooks.dart';
import 'package:pos/app/pos_bootstrap.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();

  WidgetsFlutterBinding.ensureInitialized();
  installDesktopExitGracefulShutdown();

  // Cap decoded catalog bitmap RAM (full sale snapshots stay in SQLite, not image cache).
  PaintingBinding.instance.imageCache
    ..maximumSize = 200
    ..maximumSizeBytes = 50 << 20;

  // Window appears immediately; heavy init runs inside [PosBootstrapRoot].
  runApp(const PosBootstrapRoot());
}
