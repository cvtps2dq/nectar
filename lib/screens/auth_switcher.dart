import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../theme/colors.dart';

// Placeholders for next Turn
import 'auth/login_screen.dart';
import 'auth/setup_screen.dart';
import 'home/home_screen.dart';

class AuthSwitcher extends StatelessWidget {
  const AuthSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.select((ChatProvider p) => p.authState);

    switch (authState) {
      case AuthState.connecting:
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: NeuColors.accent),
          ),
        );
      case AuthState.locked:
        return const LoginScreen();
      case AuthState.setupNeeded:
        return const SetupScreen();
      case AuthState.ready:
        return const HomeScreen();
    }
  }
}
