import 'package:flutter/material.dart';
import 'neu_box.dart';
import '../theme/colors.dart';

class NeuButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double? width;
  final double? height;
  final Color? color;
  final EdgeInsetsGeometry padding; // Allow custom padding

  const NeuButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.width,
    this.height,
    this.color,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  });

  @override
  State<NeuButton> createState() => _NeuButtonState();
}

class _NeuButtonState extends State<NeuButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (widget.onPressed != null) widget.onPressed!();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: NeuBox(
        width: widget.width,
        height: widget.height,
        color: widget.color ?? NeuColors.surface,
        isPressed: _isPressed,

        // REMOVED PADDING FROM NeuBox
        // padding: widget.padding,

        // INSTEAD, WRAP CHILD in a Padding and Center
        child: Center(
          child: Padding(
            padding: widget.padding,
            child: DefaultTextStyle(
              style: TextStyle(
                color: widget.color == NeuColors.accent
                    ? Colors.black
                    : (_isPressed ? NeuColors.accent : NeuColors.textPrimary),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
