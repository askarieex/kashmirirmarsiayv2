import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

class BeautifulPopup extends StatelessWidget {
  final String message;
  final VoidCallback onClose;
  final Color accentColor;

  const BeautifulPopup({
    super.key,
    required this.message,
    required this.onClose,
    this.accentColor = const Color(
      0xFF7B2CBF,
    ), // Updated to purple accent color
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 340,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Blurred background
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.transparent),
              ),
            ),

            // Main container with enhanced gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Color(0xFFF2E9FF), Color(0xFFE2D1FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: accentColor.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.25),
                    blurRadius: 25,
                    spreadRadius: 1,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Decorative background elements
                  Positioned(
                    top: -15,
                    right: -15,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            accentColor.withOpacity(0.1),
                            accentColor.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -20,
                    left: -20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            accentColor.withOpacity(0.1),
                            accentColor.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    left: 20,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor.withOpacity(0.07),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 60,
                    right: 25,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor.withOpacity(0.05),
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
                          const SizedBox(height: 24),
                          _buildTitle(accentColor),
                          const SizedBox(height: 20),
                          _buildMessageText(message),
                          const SizedBox(height: 32),
                          _buildCloseButton(accentColor, context),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Close icon at the top right corner
            Positioned(
              top: -10,
              right: -10,
              child: GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: accentColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced icon container with better shadows and effects
  Widget _buildIconContainer(Color accentColor) {
    return Container(
      width: 85,
      height: 85,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Color(0xFFF5F0FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 65,
          height: 65,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accentColor.withOpacity(0.15),
                accentColor.withOpacity(0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.notifications_active_rounded,
            color: accentColor,
            size: 32,
          ),
        ),
      ),
    );
  }

  // Enhanced title with better typography
  Widget _buildTitle(Color accentColor) {
    return Text(
      'New Message',
      style: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: accentColor,
        letterSpacing: 0.3,
      ),
    );
  }

  // Enhanced message text with improved styling
  Widget _buildMessageText(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.nunitoSans(
            fontSize: 16,
            color: Colors.black87,
            height: 1.6,
            letterSpacing: 0.2,
          ),
          children: _parseMessage(message),
        ),
      ),
    );
  }

  // Parse message to detect and make URLs clickable (unchanged logic)
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
          style: GoogleFonts.nunitoSans(
            color: Colors.blue.shade700,
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.w500,
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

  // Launch URL in external browser (unchanged logic)
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

  // Completely redesigned close button with gradient and effects
  Widget _buildCloseButton(Color accentColor, BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onClose,
        borderRadius: BorderRadius.circular(50),
        splashColor: accentColor.withOpacity(0.1),
        highlightColor: accentColor.withOpacity(0.05),
        child: Container(
          width: 160,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accentColor, Color(0xFF9747FF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 20,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                'Got It',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  letterSpacing: 0.5,
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
                builder:
                    (context) => BeautifulPopup(
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
