import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    debugPrint('Splash screen initialized');

    // Navigate after 3 seconds
    Timer(const Duration(milliseconds: 3000), () {
      if (mounted && !_hasNavigated) {
        _navigateToNextScreen();
      }
    });
  }

  void _navigateToNextScreen() {
    if (!mounted || _hasNavigated) return;

    setState(() {
      _hasNavigated = true;
    });

    debugPrint('Navigating to get started screen');
    Navigator.pushReplacementNamed(context, '/getStarted');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with simple shadow
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 25,
                    spreadRadius: 5,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(15),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(height: 30),

            // App title
            const Text(
              'Kashmiri Marsiya',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212529),
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 12),

            // Subtitle
            const Text(
              'Elegance in Poetry',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6C757D),
                letterSpacing: 2.0,
                fontWeight: FontWeight.w300,
              ),
            ),

            const SizedBox(height: 50),

            // Simple loading indicator
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFF1DB954).withOpacity(0.8),
                ),
                strokeWidth: 2.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
