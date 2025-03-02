import 'package:flutter/material.dart';

class NohaScreen extends StatelessWidget {
  const NohaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF191414),
      appBar: AppBar(
        title: const Text('Noha'),
        backgroundColor: const Color(0xFF191414),
      ),
      body: const Center(
        child: Text('Noha Screen', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
