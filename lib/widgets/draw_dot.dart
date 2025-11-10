import 'package:flutter/material.dart';

class DrawDot {
  const DrawDot._();

  static Widget circular({
    required double dotSize,
    required Color color,
  }) {
    return Container(
      width: dotSize,
      height: dotSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}