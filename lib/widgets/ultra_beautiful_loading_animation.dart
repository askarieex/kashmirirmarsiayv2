import 'package:flutter/material.dart';

class UltraBeautifulLoadingAnimation extends StatefulWidget {
  const UltraBeautifulLoadingAnimation({super.key});

  static const Color brandGreen = Color(0xFF008F41);

  @override
  _UltraBeautifulLoadingAnimationState createState() =>
      _UltraBeautifulLoadingAnimationState();
}

class _UltraBeautifulLoadingAnimationState
    extends State<UltraBeautifulLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildRipple(double delay) {
    final progress = (_controller.value + delay) % 1.0;
    final scale = 0.5 + progress;
    final opacity = 1.0 - progress;

    return Container(
      width: 80 * scale,
      height: 80 * scale,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: UltraBeautifulLoadingAnimation.brandGreen.withOpacity(opacity),
          width: 4,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildRipple(0.0),
          _buildRipple(0.33),
          _buildRipple(0.66),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: UltraBeautifulLoadingAnimation.brandGreen,
            ),
          ),
        ],
      ),
    );
  }
}
