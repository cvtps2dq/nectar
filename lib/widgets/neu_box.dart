import 'package:flutter/material.dart';
import '../theme/colors.dart';

class NeuBox extends StatelessWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color color;
  final bool isPressed;
  final BoxShape shape;

  const NeuBox({
    super.key,
    this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 16.0,
    this.color = NeuColors.surface,
    this.isPressed = false,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
        gradient: isPressed 
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                NeuColors.shadowDark, // Dark inside top-left
                NeuColors.shadowLight, // Light inside bottom-right
              ],
            )
          : null,
        boxShadow: isPressed
            ? null // Pressed state (Debossed) simulates inner shadow via Gradient above
            : [
                // Embossed State (Popped out)
                BoxShadow(
                  color: NeuColors.shadowDark,
                  offset: const Offset(4, 4),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: NeuColors.shadowLight,
                  offset: const Offset(-4, -4),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
      ),
      child: child,
    );
  }
}