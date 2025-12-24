import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/daemon_service.dart';
import 'providers/chat_provider.dart';
import 'theme/colors.dart';

// We will create this file in the next turn, 
// but for now, we leave the AuthSwitcher class here or 
// move it to lib/screens/auth_switcher.dart
import 'screens/auth_switcher.dart'; 

void main() {
  runZonedGuarded(() {
    final daemon = DaemonService();
    daemon.connect();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ChatProvider(daemon)),
        ],
        child: const NectarApp(),
      ),
    );
  }, (error, stack) {
    if (error.toString().contains("ZeroMQException(35)")) return;
    print("Unhandled Error: $error");
  });
}

class NectarApp extends StatelessWidget {
  const NectarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nectar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: NeuColors.background,
        primaryColor: NeuColors.accent,
        colorScheme: const ColorScheme.dark(
          primary: NeuColors.accent,
          surface: NeuColors.surface,
          background: NeuColors.background,
        ),
        useMaterial3: true,
        fontFamily: 'Satoshi', // Ensure you add fonts to pubspec.yaml if you want this
      ),
      home: const AuthSwitcher(),
    );
  }
}