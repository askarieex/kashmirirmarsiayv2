import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BeautifulPopup extends StatelessWidget {
  final String message;
  final VoidCallback onClose;
  final Color accentColor;

  const BeautifulPopup({
    super.key,
    required this.message,
    required this.onClose,
    this.accentColor = const Color(0xFF008F41), // Default green accent color
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 340,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accentColor.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 1,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 25,
                offset: const Offset(0, 15),
              ),
            ],
            gradient: LinearGradient(
              colors: [Colors.white, Color(0xFFF0F8F6), Color(0xFFE6F5F0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Decorative background circles
              Positioned(
                top: -10,
                right: -10,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withOpacity(0.05),
                  ),
                ),
              ),
              Positioned(
                bottom: -15,
                left: -15,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withOpacity(0.07),
                  ),
                ),
              ),
              // Scrollable content
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 34, 24, 34),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildIconContainer(accentColor),
                      const SizedBox(height: 20),
                      _buildTitle(accentColor),
                      const SizedBox(height: 16),
                      _buildMessageText(message),
                      const SizedBox(height: 32),
                      _buildCloseButton(accentColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Icon container with shadow and accent color
  Widget _buildIconContainer(Color accentColor) {
    return Container(
      width: 75,
      height: 75,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.15),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.notifications_active_outlined,
            color: accentColor,
            size: 30,
          ),
        ),
      ),
    );
  }

  // Title text with accent color
  Widget _buildTitle(Color accentColor) {
    return Text(
      'Alert',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: accentColor,
        letterSpacing: 0.3,
      ),
    );
  }

  // Message text with clickable URLs
  Widget _buildMessageText(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            height: 1.5,
            letterSpacing: 0.2,
          ),
          children: _parseMessage(message),
        ),
      ),
    );
  }

  // Parse message to detect and make URLs clickable
  List<TextSpan> _parseMessage(String message) {
    final urlPattern = RegExp(r'https?://[^\s]+');
    final matches = urlPattern.allMatches(message);
    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: message.substring(lastEnd, match.start)));
      }
      final url = message.substring(match.start, match.end);
      spans.add(
        TextSpan(
          text: url,
          style: const TextStyle(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()..onTap = () => _launchURL(url),
        ),
      );
      lastEnd = match.end;
    }
    if (lastEnd < message.length) {
      spans.add(TextSpan(text: message.substring(lastEnd)));
    }
    return spans;
  }

  // Launch URL in external browser
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        print('Could not launch $url');
      }
    } catch (e) {
      print('Error launching URL: $e');
    }
  }

  // Close button with custom styling
  Widget _buildCloseButton(Color accentColor) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onClose,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          width: 120,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: Colors.grey.shade300, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.close, size: 18, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              Text(
                'Close',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Example usage in a Flutter app
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Beautiful Popup Example')),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => BeautifulPopup(
                  message:
                      'Visit https://example.com or https://flutter.dev for details.',
                  onClose: () => Navigator.of(context).pop(),
                ),
              );
            },
            child: const Text('Show Popup'),
          ),
        ),
      ),
    );
  }
}