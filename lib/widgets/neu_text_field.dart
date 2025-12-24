import 'package:flutter/material.dart';
import 'neu_box.dart';
import '../theme/colors.dart';

class NeuTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final bool obscureText;
  final Widget? prefixIcon;
  final ValueChanged<String>? onSubmitted;

  const NeuTextField({
    super.key,
    this.controller,
    this.hintText = "",
    this.obscureText = false,
    this.prefixIcon,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return NeuBox(
      isPressed: true, // "Sunk" effect
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        onSubmitted: onSubmitted,
        style: const TextStyle(color: NeuColors.textPrimary),
        cursorColor: NeuColors.accent,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: const TextStyle(color: NeuColors.textSecondary),
          icon: prefixIcon,
        ),
      ),
    );
  }
}