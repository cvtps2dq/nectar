import 'dart:io';
import 'package:flutter/material.dart';
import 'neu_box.dart';
import '../theme/colors.dart';

class NeuAvatar extends StatelessWidget {
  final String? imagePath;
  final String fallbackName; // e.g. "Alice" -> "A"
  final double size;
  final bool isOnline;

  const NeuAvatar({
    super.key,
    this.imagePath,
    required this.fallbackName,
    this.size = 50,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        NeuBox(
          width: size,
          height: size,
          padding: EdgeInsets.zero,
          shape: BoxShape.circle,
          // If image exists, we don't press it. If text, we emboss it.
          child: ClipOval(
            child: (imagePath != null && imagePath!.isNotEmpty && File(imagePath!).existsSync())
                ? Image.file(
                    File(imagePath!),
                    fit: BoxFit.cover,
                    width: size,
                    height: size,
                  )
                : Center(
                    child: Text(
                      fallbackName.isNotEmpty ? fallbackName[0].toUpperCase() : "?",
                      style: TextStyle(
                        fontSize: size * 0.4,
                        fontWeight: FontWeight.bold,
                        color: NeuColors.textSecondary,
                      ),
                    ),
                  ),
          ),
        ),
        if (isOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: NeuColors.green,
                shape: BoxShape.circle,
                border: Border.all(color: NeuColors.background, width: 2),
                boxShadow: [
                  BoxShadow(color: NeuColors.green.withOpacity(0.5), blurRadius: 4, spreadRadius: 1)
                ]
              ),
            ),
          )
      ],
    );
  }
}