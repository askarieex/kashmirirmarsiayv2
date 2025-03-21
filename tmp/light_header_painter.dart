import 'package:flutter/material.dart';

class LightHeaderPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Draw subtle light pattern
    final Paint dotPaint =
        Paint()
          ..color = const Color(0xFF00875A).withOpacity(0.05)
          ..style = PaintingStyle.fill;

    // Draw subtle dots pattern
    double dotSpacing = 25;
    double dotRadius = 4;
    for (double x = dotSpacing; x < size.width; x += dotSpacing) {
      for (double y = dotSpacing; y < size.height; y += dotSpacing) {
        // Add some randomness to dot size and opacity
        double randomFactor = 0.5 + (x * y) % 1.0;
        canvas.drawCircle(
          Offset(x, y),
          dotRadius * randomFactor,
          Paint()
            ..color = const Color(0xFF00875A).withOpacity(0.04 * randomFactor),
        );
      }
    }

    // Add a few larger decorative circles
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.5),
      20,
      Paint()..color = const Color(0xFF00875A).withOpacity(0.05),
    );

    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.2),
      15,
      Paint()..color = const Color(0xFF00875A).withOpacity(0.07),
    );

    canvas.drawCircle(
      Offset(size.width * 0.65, size.height * 0.7),
      25,
      Paint()..color = const Color(0xFF00875A).withOpacity(0.04),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
