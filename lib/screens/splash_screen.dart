import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _rotateAnim;
  late Animation<Color?> _colorAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Fade in animation with a slight delay
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
      ),
    );

    // Scale animation with bounce effect
    _scaleAnim = TweenSequenceItem(
      weight: 100.0,
      tween: TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.6, end: 1.1),
          weight: 60.0,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.1, end: 1.0),
          weight: 40.0,
        ),
      ]),
    ).tween.animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    // Subtle rotation animation
    _rotateAnim = Tween<double>(begin: -0.05, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Background color animation
    _colorAnim = ColorTween(
      begin: Colors.white,
      end: const Color(0xFFF8F9FA),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    // Preload home screen data before transitioning
    _preloadAndNavigate();
  }

  // Preload home screen data and then navigate
  Future<void> _preloadAndNavigate() async {
    // Wait for animations to start
    await Future.delayed(const Duration(milliseconds: 1500));

    // Preload any required assets or data here

    // Make sure we finish the animation first
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      // Use a fade transition when navigating
      Navigator.pushReplacementNamed(
        context,
        '/mainNav',
        arguments: {'preloaded': true},
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: _colorAnim.value,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [const Color(0xFFF8F9FA), const Color(0xFFE9ECEF)],
              ),
            ),
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: RotationTransition(
                  turns: _rotateAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo with shadow
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: Image.asset('assets/images/logo.png'),
                        ),
                        const SizedBox(height: 32),

                        // Main title with gradient
                        ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return const LinearGradient(
                              colors: [
                                Color.fromARGB(255, 255, 255, 255),
                                Color.fromARGB(255, 255, 255, 255),
                              ],
                            ).createShader(bounds);
                          },
                          child: const Text(
                            'Kashmiri Marsiya',
                            style: TextStyle(
                              color: Color.fromARGB(255, 0, 0, 0),
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Subtitle with fade in effect
                        FadeTransition(
                          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _controller,
                              curve: const Interval(
                                0.6,
                                1.0,
                                curve: Curves.easeIn,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Elegance in Poetry',
                            style: TextStyle(
                              color: Color(0xFF495057),
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 3.0,
                            ),
                          ),
                        ),

                        const SizedBox(height: 50),

                        // Loading indicator
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF6C63FF).withOpacity(0.8),
                            ),
                            strokeWidth: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
