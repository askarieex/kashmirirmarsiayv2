import 'package:flutter/material.dart';

class HelpUsScreen extends StatelessWidget {
  const HelpUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help Us')),
      body: const Center(child: Text('Help Us Screen')),
    );
  }
}
