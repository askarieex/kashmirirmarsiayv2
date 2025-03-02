import 'package:flutter/material.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF191414),
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: const Color(0xFF191414),
      ),
      body: const Center(
        child: Text('Search Screen', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
