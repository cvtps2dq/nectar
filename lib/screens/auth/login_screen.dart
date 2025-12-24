import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../theme/colors.dart';
import '../../widgets/neu_box.dart';
import '../../widgets/neu_button.dart';
import '../../widgets/neu_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _passCtrl = TextEditingController();

  void _unlock() {
    context.read<ChatProvider>().unlock(_passCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final authError = context.select((ChatProvider p) => p.authError);

    return Scaffold(
      backgroundColor: NeuColors.background,
      body: Center(
        child: NeuBox(
          width: 350,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "NECTAR",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: NeuColors.textPrimary,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "SECURE ENVIRONMENT",
                style: TextStyle(
                  fontSize: 10,
                  color: NeuColors.accent,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 40),

              if (authError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    authError,
                    style: const TextStyle(color: NeuColors.red, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),

              NeuTextField(
                controller: _passCtrl,
                hintText: "Database Password",
                obscureText: true,
                prefixIcon: const Icon(
                  Icons.lock_outline,
                  color: NeuColors.textSecondary,
                ),
                onSubmitted: (_) => _unlock(),
              ),

              const SizedBox(height: 32),

              NeuButton(
                onPressed: _unlock,
                color: NeuColors.accent,
                child: const Text("UNLOCK SYSTEM"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
